import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = (
    Path(__file__).resolve().parents[1]
    / "home/.config/television/cable/worktrees.py"
)
spec = importlib.util.spec_from_file_location("worktrees", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class WorktreeDeletionTests(unittest.TestCase):
    def setUp(self):
        temporary = self.enterContext(tempfile.TemporaryDirectory())
        self.root = Path(temporary)
        self.parent = self.root / "parent"
        self.target = self.root / "task"
        self.parent.mkdir()
        self.target.mkdir()
        self.selected = {"parent": str(self.parent), "path": str(self.target)}
        self.panes = []
        self.status = {}
        self.output = self.enterContext(contextlib.redirect_stderr(io.StringIO()))
        self.enterContext(patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "current"}))
        self.enterContext(patch.object(worktrees, "brazil_workspace", return_value=None))
        self.enterContext(patch.object(worktrees.subprocess, "check_output", side_effect=self.query))
        self.run = self.enterContext(patch.object(worktrees.subprocess, "run"))
        self.confirm = self.enterContext(patch.object(worktrees, "prompt", return_value="ok"))

    def query(self, command, **kwargs):
        if command == ["herdr", "api", "snapshot"]:
            return json.dumps({"result": {"snapshot": {"panes": self.panes}}}).encode()
        if command[:1] == ["git"] and command[3:] == ["status", "--porcelain"]:
            return self.status.get(command[2], b"")
        raise AssertionError(command)

    def pane(self, pane_id, cwd, foreground_cwd=None):
        self.panes.append({
            "pane_id": pane_id, "cwd": str(cwd),
            "foreground_cwd": str(foreground_cwd) if foreground_cwd else None,
        })

    def commands(self):
        return [call.args[0] for call in self.run.call_args_list]

    def remove_command(self):
        return ["git", "-C", str(self.parent), "worktree", "remove", str(self.target)]

    def test_confirmed_delete_warns_and_closes_only_target_panes(self):
        self.pane("target", self.target / "src")
        self.pane("unrelated", self.parent)
        worktrees.delete_worktree(self.selected)
        self.confirm.assert_called_once_with("Type ok to delete (blank cancels): ")
        self.assertIn("target", self.output.getvalue())
        self.assertEqual(self.commands(), [
            self.remove_command(),
            ["herdr", "pane", "close", "target"],
        ])

    def test_dirty_worktree_is_force_deleted_after_confirmation(self):
        self.status[str(self.target)] = b" M tracked.py\n?? untracked.txt\n"
        worktrees.delete_worktree(self.selected)
        self.assertIn("Uncommitted changes", self.output.getvalue())
        self.assertEqual(self.commands(), [self.remove_command() + ["--force"]])

    def test_clean_shell_deletion_preserves_normal_and_force_modes(self):
        with patch.dict(os.environ, {"HERDR_ENV": "0"}):
            for force in (False, True):
                with self.subTest(force=force):
                    self.run.reset_mock()
                    worktrees.delete_worktree(self.selected, force=force)
                    self.assertEqual(
                        self.commands(), [self.remove_command() + (["--force"] if force else [])],
                    )

    def test_cancelling_preserves_changes_and_panes(self):
        self.pane("target", self.target)
        self.status[str(self.target)] = b" M tracked.py\n"
        for answer in ["", "yes", "OK", self.target.name]:
            with self.subTest(answer=answer):
                self.confirm.return_value = answer
                worktrees.delete_worktree(self.selected, force=True)
                self.run.assert_not_called()

    def test_delete_failure_keeps_panes_open(self):
        self.pane("target", self.target)
        self.run.side_effect = subprocess.CalledProcessError(1, self.remove_command())
        with self.assertRaises(subprocess.CalledProcessError):
            worktrees.delete_worktree(self.selected, force=True)
        self.assertEqual(self.commands(), [self.remove_command() + ["--force"]])

    def test_current_pane_closes_last_after_deleting_its_directory(self):
        self.pane("current", self.target)
        self.pane("other", self.parent, self.target / "src")
        with patch.object(worktrees.Path, "cwd", return_value=self.target):
            worktrees.delete_worktree(self.selected)
        self.assertEqual(self.commands(), [
            self.remove_command(),
            ["herdr", "pane", "close", "other"],
            ["herdr", "pane", "close", "current"],
        ])
        for call in self.run.call_args_list:
            self.assertEqual(call.kwargs["cwd"], self.parent)

    def test_brazil_checks_all_packages_for_changes(self):
        owner = self.root / "owner"
        workspace = owner / "worktrees/task"
        first, second = workspace / "src/First", workspace / "src/Second"
        self.status[str(second)] = b" M tracked.py\n"
        self.pane("sibling", second)
        selected = {"parent": str(owner / "src/First"), "path": str(first)}
        with (
            patch.object(worktrees, "brazil_workspace", side_effect=[owner, workspace]),
            patch.object(worktrees, "repositories", return_value=[first, second]),
        ):
            worktrees.delete_worktree(selected)
        self.assertIn(str(second), self.output.getvalue())
        self.assertEqual(self.commands(), [
            ["brazil", "worktree", "delete", "--workspace", str(owner),
             "--name", "task", "--force"],
            ["herdr", "pane", "close", "sibling"],
        ])

    def test_clean_brazil_worktree_still_forces_branch_deletion(self):
        owner = self.root / "owner"
        workspace = owner / "worktrees/task"
        package = workspace / "src/Package"
        selected = {"parent": str(owner / "src/Package"), "path": str(package)}
        with (
            patch.object(worktrees, "brazil_workspace", side_effect=[owner, workspace]),
            patch.object(worktrees, "repositories", return_value=[package]),
        ):
            worktrees.delete_worktree(selected)
        self.confirm.assert_called_once_with("Type ok to delete (blank cancels): ")
        self.assertIn("including unmerged branches", self.output.getvalue())
        self.assertEqual(self.commands(), [
            ["brazil", "worktree", "delete", "--workspace", str(owner),
             "--name", "task", "--force"],
        ])

    def test_confirmed_delete_removes_readonly_cache_directories(self):
        cache = self.target / "tmp/gomodcache/module"
        cache.mkdir(parents=True)
        (cache / "source.go").write_text("fixture")
        (cache / "source.go").chmod(0o444)
        cache.chmod(0o555)
        self.run.side_effect = lambda *args, **kwargs: shutil.rmtree(self.target)
        worktrees.delete_worktree(self.selected)
        self.assertFalse(self.target.exists())

    def test_cancelling_leaves_cache_permissions_unchanged(self):
        cache = self.target / "tmp/gomodcache/module"
        cache.mkdir(parents=True)
        cache.chmod(0o555)
        self.confirm.return_value = ""
        worktrees.delete_worktree(self.selected)
        self.assertEqual(stat.S_IMODE(cache.stat().st_mode), 0o555)
        self.run.assert_not_called()

    def test_shared_cache_symlink_is_not_followed(self):
        shared = self.root / "shared-cache"
        shared.mkdir()
        (shared / "source.go").write_text("shared fixture")
        shared.chmod(0o555)
        (self.target / "cache").symlink_to(shared, target_is_directory=True)
        self.run.side_effect = lambda *args, **kwargs: shutil.rmtree(self.target)
        worktrees.delete_worktree(self.selected)
        self.assertFalse(self.target.exists())
        self.assertEqual(stat.S_IMODE(shared.stat().st_mode), 0o555)
        self.assertEqual((shared / "source.go").read_text(), "shared fixture")

    def test_primary_checkout_is_still_protected(self):
        with self.assertRaisesRegex(ValueError, "primary checkout"):
            worktrees.delete_worktree(
                {"parent": str(self.parent), "path": str(self.parent)}, force=True,
            )
        self.confirm.assert_not_called()
        self.run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
