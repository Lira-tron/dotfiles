import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("artifact_worktrees", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class ArtifactWorktreeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.owner = self.root / "workspace"
        self.parent = self.owner / "src/First"
        self.parent.mkdir(parents=True)
        (self.parent / ".git").mkdir()
        second = self.owner / "src/Second"
        second.mkdir()
        (second / ".git").mkdir()
        self.tool = self.root / ".local/bin/ai-artifacts"
        self.tool.parent.mkdir(parents=True)
        self.tool.write_text("fixture")
        self.commands = []

    def query(self, command, **kwargs):
        if command == ["brazil-context", "package", "root"]:
            return str(self.parent).encode()
        if command == ["brazil-context", "workspace", "root"]:
            return str(self.owner).encode()
        if command[-1] == "HEAD":
            return b"1234567890abcdef"
        if command[-2:] == ["branch", "--show-current"]:
            return b"mainline"
        raise AssertionError(command)

    def run_command(self, command, **kwargs):
        self.commands.append(command)
        if "show-ref" in command:
            return subprocess.CompletedProcess(command, 1)
        if command[:3] == ["brazil", "worktree", "create"]:
            name = command[command.index("--name") + 1]
            for package in ("First", "Second"):
                p = self.owner / "worktrees" / name / "src" / package
                p.mkdir(parents=True)
                (p / ".git").write_text("gitdir: fixture")
        return subprocess.CompletedProcess(command, 0)

    def test_creation_initializes_each_package_with_same_feature_date(self):
        now = worktrees.datetime.now(worktrees.timezone.utc)
        name = "feature-work-" + now.strftime("%m%d")
        with (
            patch.object(worktrees.Path, "home", return_value=self.root),
            patch.object(worktrees, "prompt", return_value=name),
            patch.object(worktrees.subprocess, "check_output", side_effect=self.query),
            patch.object(worktrees.subprocess, "run", side_effect=self.run_command),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            created = worktrees.create_worktree({"parent": str(self.parent)})
        self.assertEqual(created["path"], str(self.owner / "worktrees" / name / "src/First"))
        initializations = [c for c in self.commands if c[0] == str(self.tool)]
        self.assertEqual(initializations, [
            [str(self.tool), "init", "--cwd",
             str(self.owner / "worktrees" / name / "src" / package),
             "--feature", "feature-work", "--date", now.strftime("%y-%m-%d")]
            for package in ("First", "Second")
        ])

    def test_missing_helper_does_not_create_worktree(self):
        self.tool.unlink()
        with (
            patch.object(worktrees.Path, "home", return_value=self.root),
            patch.object(worktrees, "prompt", return_value="feature-work"),
            patch.object(worktrees.subprocess, "check_output", side_effect=self.query),
            patch.object(worktrees.subprocess, "run", side_effect=self.run_command),
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaisesRegex(ValueError, "Install the shared"),
        ):
            worktrees.create_worktree({"parent": str(self.parent)})
        self.assertEqual(self.commands, [])

    def test_legacy_artifacts_block_even_forced_deletion(self):
        target = self.root / "task"
        (target / ".ai").mkdir(parents=True)
        (target / ".ai/spec.md").write_text("retain")
        with (
            patch.dict(os.environ, {"HERDR_ENV": "0"}),
            patch.object(worktrees, "brazil_workspace", return_value=None),
            patch.object(worktrees.subprocess, "run") as run,
            self.assertRaisesRegex(ValueError, "Preserve and migrate"),
        ):
            worktrees.delete_worktree({"parent": str(self.parent), "path": str(target)}, force=True)
        run.assert_not_called()
        self.assertEqual((target / ".ai/spec.md").read_text(), "retain")

    def test_external_artifact_link_survives_checkout_cleanup(self):
        target = self.root / "task"
        target.mkdir()
        external = self.root / "knowledge/ai/artifacts/First/26-10-19-feature-work"
        external.mkdir(parents=True)
        (external / "spec.md").write_text("retain")
        (target / ".ai").symlink_to(external, target_is_directory=True)
        with (
            patch.dict(os.environ, {"HERDR_ENV": "0"}),
            patch.object(worktrees, "brazil_workspace", return_value=None),
            patch.object(worktrees, "prompt", return_value="ok"),
            patch.object(worktrees.subprocess, "check_output", return_value=b""),
            patch.object(worktrees.subprocess, "run", side_effect=lambda *a, **kw: shutil.rmtree(target)),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            worktrees.delete_worktree({"parent": str(self.parent), "path": str(target)})
        self.assertFalse(target.exists())
        self.assertEqual((external / "spec.md").read_text(), "retain")

    def test_link_to_artifacts_inside_checkout_blocks_deletion(self):
        target = self.root / "task"
        (target / "data").mkdir(parents=True)
        (target / ".ai").symlink_to(target / "data", target_is_directory=True)
        with (
            patch.dict(os.environ, {"HERDR_ENV": "0"}),
            patch.object(worktrees, "brazil_workspace", return_value=None),
            self.assertRaisesRegex(ValueError, "outside the worktree"),
        ):
            worktrees.delete_worktree({"parent": str(self.parent), "path": str(target)})
        self.assertTrue(target.exists())


if __name__ == "__main__":
    unittest.main()
