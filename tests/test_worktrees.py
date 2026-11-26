import contextlib
import base64
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).absolute().parents[1] / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("worktrees", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class NamedWorktreeTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.parent = self.root / "workspace/src/Package"
        (self.parent / ".git").mkdir(parents=True)
        (self.parent.parent / "notes.txt").touch()
        self.created = self.root / "workspace/worktrees/feature-work/src/Package"
        (self.created / ".git").mkdir(parents=True)
        (self.created.parent / "notes.txt").touch()
        self.tool = self.root / ".local/bin/ai-artifacts"
        self.tool.parent.mkdir(parents=True)
        self.tool.touch()
        self.enterContext(patch.object(worktrees.Path, "home", return_value=self.root))
        self.enterContext(patch.object(worktrees.subprocess, "check_output", side_effect=[
            str(self.parent).encode(), str(self.root / "workspace").encode(), b"1234567890abcdef", b"main",
        ]))
        self.run = self.enterContext(patch.object(
            worktrees.subprocess, "run", return_value=subprocess.CompletedProcess([], 1),
        ))
        self.prompt = self.enterContext(patch.object(worktrees, "prompt", return_value="feature-work"))
        self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def test_explicit_name_creates_without_reading_a_terminal(self):
        result = worktrees.create_worktree({"parent": str(self.parent)}, name="feature-work")
        self.assertEqual(result, {"parent": str(self.parent), "path": str(self.created)})
        self.prompt.assert_not_called()
        self.assertIn(
            ["brazil", "worktree", "create", "--workspace", str(self.root / "workspace"),
             "--name", "feature-work", "--inheritAll"],
            [call.args[0] for call in self.run.call_args_list],
        )

    def test_omitted_name_keeps_the_interactive_prompt(self):
        worktrees.create_worktree({"parent": str(self.parent)})
        self.prompt.assert_called_once_with("New worktree name (blank cancels): ")

    def test_explicit_blank_name_cancels_without_prompt_or_mutation(self):
        self.assertIsNone(worktrees.create_worktree({"parent": str(self.parent)}, name=""))
        self.prompt.assert_not_called()
        self.run.assert_not_called()

    def test_invalid_explicit_name_keeps_existing_validation(self):
        with self.assertRaisesRegex(ValueError, "without slashes"):
            worktrees.create_worktree({"parent": str(self.parent)}, name="../escape")
        self.prompt.assert_not_called()
        self.run.assert_not_called()

    def test_existing_branch_prevents_creation(self):
        self.run.return_value = subprocess.CompletedProcess([], 0)
        with self.assertRaisesRegex(ValueError, "already exists"):
            worktrees.create_worktree({"parent": str(self.parent)}, name="feature-work")
        self.assertFalse(any(call.args[0][0] == "brazil" for call in self.run.call_args_list))


class WorktreeFeatureTests(unittest.TestCase):
    def test_rejects_paths_and_option_names(self):
        created = worktrees.datetime(2026, 11, 26, tzinfo=worktrees.timezone.utc)
        for name in ("../escape", "path\\escape", "-option"):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "without slashes"):
                worktrees.worktree_feature(name, created)

    def test_rejects_names_outside_lowercase_kebab_case(self):
        created = worktrees.datetime(2026, 11, 26, tzinfo=worktrees.timezone.utc)
        for name in ("Uppercase", "space name", "trailing-", "double--dash", ""):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "lowercase kebab-case"):
                worktrees.worktree_feature(name, created)

    def test_keeps_feature_name_and_removes_only_the_current_date_suffix(self):
        created = worktrees.datetime(2026, 11, 26, tzinfo=worktrees.timezone.utc)
        for name, expected in (("feature-work", "feature-work"), ("feature-work-1126", "feature-work"),
                               ("feature-work-1125", "feature-work-1125")):
            with self.subTest(name=name):
                self.assertEqual(worktrees.worktree_feature(name, created), expected)


class DeletionConfirmationTests(unittest.TestCase):
    def test_native_confirmation_replaces_only_the_terminal_question(self):
        with tempfile.TemporaryDirectory() as directory:
            parent, target = Path(directory) / "parent", Path(directory) / "task"
            parent.mkdir()
            target.mkdir()
            for status, answer in ((b"", "ok"), (b" M changed.txt\n", "ok"), (b" M changed.txt\n", "cancel")):
                with (
                    self.subTest(status=status, answer=answer),
                    patch.dict(os.environ, {"HERDR_ENV": "1"}),
                    patch.object(worktrees, "brazil_workspace", return_value=None),
                    patch.object(worktrees.subprocess, "check_output", return_value=status),
                    patch.object(worktrees.subprocess, "run") as run,
                    patch.object(worktrees, "prompt", side_effect=AssertionError("Terminal prompt used")),
                    contextlib.redirect_stderr(io.StringIO()) as output,
                ):
                    def confirm(message):
                        self.assertIn("Type ok to delete", message)
                        self.assertEqual("Uncommitted changes will be discarded" in output.getvalue(), bool(status))
                        return answer

                    worktrees.delete_worktree(
                        {"parent": str(parent), "path": str(target)}, confirm=confirm,
                    )
                    self.assertEqual(run.call_count, 1 if answer == "ok" else 0)
                    if answer == "ok":
                        self.assertEqual("--force" in run.call_args.args[0], bool(status))

    def test_failed_git_removal_raises_and_keeps_the_target(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryFile(mode="w+t") as output:
            parent, target = Path(directory) / "not-a-repository", Path(directory) / "task"
            parent.mkdir()
            target.mkdir()
            (target / "keep.txt").write_text("keep")
            with (
                patch.dict(os.environ, {"HERDR_ENV": "0"}),
                patch.object(worktrees, "brazil_workspace", return_value=None),
                patch.object(worktrees.subprocess, "check_output", return_value=b""),
                contextlib.redirect_stderr(output),
                self.assertRaises(subprocess.CalledProcessError),
            ):
                worktrees.delete_worktree(
                    {"parent": str(parent), "path": str(target)}, confirm=lambda _: "ok",
                )
            self.assertEqual((target / "keep.txt").read_text(), "keep")


class WorkplaceRootTests(unittest.TestCase):
    def test_all_worktrees_honor_the_root_override_and_default(self):
        for configured, expected in (("/tmp/my projects", "/tmp/my projects"), ("", "/example-home/workplace")):
            with (
                self.subTest(configured=configured),
                patch.dict(os.environ, {"WORKPLACE_DIR": configured}),
                patch.object(worktrees.Path, "home", return_value=Path("/example-home")),
                patch.object(worktrees.sys, "argv", [str(SOURCE), "all"]),
                patch.object(worktrees, "workplace_rows", return_value=[]) as rows,
                contextlib.redirect_stdout(io.StringIO()),
            ):
                worktrees.main()
                rows.assert_called_once_with(Path(expected))


class RexWorktreeIntegrationTests(unittest.TestCase):
    def test_standalone_rex_discovers_and_deletes_without_herdr_or_cable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            rex_dir, bin_dir = root / "rex", root / "bin"
            rex_dir.mkdir()
            bin_dir.mkdir()
            shutil.copy2(SOURCE, rex_dir / SOURCE.name)
            standalone_spec = importlib.util.spec_from_file_location("standalone_worktrees", rex_dir / SOURCE.name)
            standalone = importlib.util.module_from_spec(standalone_spec)
            standalone_spec.loader.exec_module(standalone)
            for executable in ("git", "fd"):
                (bin_dir / executable).symlink_to(shutil.which(executable))
            environment = {"PATH": str(bin_dir), "HERDR_ENV": "1", "HERDR_PANE_ID": "unrelated"}
            parent, target = root / "parent", root / "task"
            subprocess.run(
                ["git", "clone", "--shared", "--no-checkout", str(SOURCE.parents[3]), str(parent)],
                check=True, capture_output=True,
            )
            subprocess.run(
                ["git", "-C", str(parent), "worktree", "add", "--detach", str(target), "HEAD"],
                check=True, capture_output=True,
            )
            external = root / "artifacts"
            external.mkdir()
            (external / "notes.md").write_text("keep")
            (target / ".ai").symlink_to(external, target_is_directory=True)
            (target / "uncommitted.txt").write_text("local changes")
            with patch.dict(os.environ, environment), tempfile.TemporaryFile(mode="w+t") as output:
                self.assertIsNone(shutil.which("herdr"))
                self.assertIsNone(shutil.which("brazil-context"))
                entries = standalone.current_rows(parent)
                self.assertEqual(len(entries), 1)
                selected = json.loads(base64.urlsafe_b64decode(entries[0].split("\t")[1]))
                self.assertEqual(selected, {"parent": str(parent), "path": str(target)})
                with contextlib.redirect_stderr(output):
                    standalone.delete_worktree(selected, confirm=lambda _: "cancel")
                    self.assertEqual((target / "uncommitted.txt").read_text(), "local changes")
                    standalone.delete_worktree(selected, confirm=lambda _: "ok")
                output.seek(0)
                self.assertIn("Uncommitted changes will be discarded", output.read())
                self.assertFalse(target.exists())
                self.assertEqual(len(standalone.checkouts(parent)), 1)
            self.assertTrue(parent.is_dir())
            self.assertEqual((external / "notes.md").read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
