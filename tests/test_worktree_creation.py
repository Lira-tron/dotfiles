import base64
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("worktree_creation", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class WorktreeCreationTests(unittest.TestCase):
    def test_current_creation_uses_primary_checkout_of_callers_package(self):
        parent = Path("/workspace/Pipeline/src/Constructs")
        task = Path("/workspace/Pipeline/worktrees/task/src/Constructs")
        for caller, package in [(parent, parent), (parent / "lib", parent), (task / "lib", task)]:
            with self.subTest(caller=caller):
                def query(command, **kwargs):
                    if command == ["brazil-context", "package", "root"]:
                        self.assertEqual(kwargs["cwd"], caller)
                        return os.fsencode(package)
                    self.assertEqual(command, [
                        "git", "-C", str(package), "worktree", "list", "--porcelain", "-z",
                    ])
                    return os.fsencode(f"worktree {parent}\0\0worktree {task}\0\0")

                with (
                    patch.object(worktrees.sys, "argv", [str(SOURCE), "create-current"]),
                    patch.object(worktrees.Path, "cwd", return_value=caller),
                    patch.object(worktrees.subprocess, "check_output", side_effect=query),
                    patch.object(worktrees, "create_worktree", return_value=None) as create,
                ):
                    worktrees.main()
                self.assertEqual(create.call_args.args[0]["parent"], str(parent))
                create.assert_called_once()

    def test_current_creation_outside_brazil_does_not_create_anything(self):
        with (
            patch.object(worktrees.sys, "argv", [str(SOURCE), "create-current"]),
            patch.object(worktrees.subprocess, "check_output", side_effect=subprocess.CalledProcessError(
                1, ["brazil-context", "package", "root"], stderr=b"Not in a Brazil package",
            )),
            patch.object(worktrees, "create_worktree") as create,
            self.assertRaises(subprocess.CalledProcessError),
        ):
            worktrees.main()
        create.assert_not_called()

    def test_selected_creation_still_opens_the_selected_repositories_new_tree(self):
        selected = {"parent": "/workspace/Other/src/Other", "path": "/workspace/Other/worktrees/old"}
        created = {"parent": selected["parent"], "path": "/workspace/Other/worktrees/new"}
        token = base64.urlsafe_b64encode(json.dumps(selected).encode()).decode()
        with (
            patch.dict(os.environ, {"HERDR_ENV": "1"}),
            patch.object(worktrees.sys, "argv", [str(SOURCE), "create", token]),
            patch.object(worktrees, "create_worktree", return_value=created) as create,
            patch.object(worktrees, "open_worktree") as open_tree,
        ):
            worktrees.main()
        create.assert_called_once_with(selected)
        open_tree.assert_called_once_with(created)


class TvwCreationTests(unittest.TestCase):
    def setUp(self):
        self.temp = self.enterContext(tempfile.TemporaryDirectory())
        self.root = Path(self.temp)
        self.created = self.root / "created"
        self.created.mkdir()
        self.calls = self.root / "calls"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name, body in {
            "tv": 'printf "%s\\n" "$@" > "$TV_TEST_ARGS"\nprintf "%s\\n" "$TV_TEST_SELECTION"\n',
            "python3": 'printf "%s\\n" "$@" > "$TV_TEST_CALLS"\nprintf "%s\\n" "$TV_TEST_CREATED"\n',
        }.items():
            path = self.bin / name
            path.write_text("#!/bin/sh\n" + body)
            path.chmod(0o755)

    def run_tvw(self, herdr, selection=""):
        environment = {
            **os.environ, "HERDR_ENV": herdr, "TV_TEST_BIN": str(self.bin),
            "TV_TEST_SOURCE": str(ROOT / "home/.config/zsh/tvw.zsh"),
            "TV_TEST_ARGS": str(self.root / "tv-args"), "TV_TEST_CALLS": str(self.calls),
            "TV_TEST_CREATED": str(self.created), "TV_TEST_SELECTION": selection,
        }
        return subprocess.run(
            ["zsh", "-f", "-c", 'source "$TV_TEST_SOURCE"; PATH="$TV_TEST_BIN:$PATH"; tvw; pwd'],
            cwd=self.root, env=environment, capture_output=True, text=True, check=True,
        )

    def test_herdr_picker_overrides_creation_to_use_current_folder(self):
        self.run_tvw("1")
        arguments = (self.root / "tv-args").read_text().splitlines()
        self.assertIn('ctrl-g="actions:create_current"', arguments[arguments.index("--keybindings") + 1])

    def test_shell_picker_creates_from_current_folder_with_foreign_or_empty_selection(self):
        for selection in ["ctrl-g\nforeign-workspace-token", "ctrl-g"]:
            with self.subTest(selection=selection):
                result = self.run_tvw("0", selection)
                self.assertEqual(self.calls.read_text().splitlines()[1:], ["create-current"])
                self.assertEqual(result.stdout.strip(), str(self.created))


if __name__ == "__main__":
    unittest.main()
