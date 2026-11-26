import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).absolute().parents[1] / "home/.config/television/cable/worktrees.py"
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


if __name__ == "__main__":
    unittest.main()
