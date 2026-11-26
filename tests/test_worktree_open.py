import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("worktree_open", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class WorktreeOpenTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory())).resolve()
        self.owner = self.root / "Service"
        self.task = self.owner / "worktrees/task"
        for workspace in [self.owner, self.task]:
            workspace.mkdir(parents=True)
            (workspace / "packageInfo").touch()
            for package in ["Service", "ServiceCDK"]:
                repo = workspace / "src" / package
                repo.mkdir(parents=True)
                (repo / ".git").touch()
        self.selected = {
            "parent": str(self.owner / "src/ServiceCDK"),
            "path": str(self.task / "src/ServiceCDK"),
        }
        self.workspaces = []
        self.panes = []
        self.enterContext(patch.object(
            worktrees, "brazil_workspace",
            side_effect=lambda path: self.task if path.is_relative_to(self.task) else self.owner,
        ))
        self.enterContext(patch.object(
            worktrees.subprocess, "check_output", side_effect=self.snapshot,
        ))
        self.run = self.enterContext(patch.object(worktrees.subprocess, "run"))

    def snapshot(self, command):
        self.assertEqual(command, ["herdr", "api", "snapshot"])
        return json.dumps({"result": {"snapshot": {
            "workspaces": self.workspaces, "panes": self.panes,
        }}}).encode()

    def workspace(self, identifier, repo, linked=False):
        self.workspaces.append({
            "workspace_id": identifier,
            "worktree": {
                "checkout_path": str(repo), "is_linked_worktree": linked,
            },
        })

    def assert_open(self, parent, target):
        self.run.assert_called_once_with(
            ["herdr", "worktree", "open", "--cwd", str(parent),
             "--path", str(target), "--focus"],
            check=True,
        )

    def test_new_task_selected_through_cdk_uses_service_parent(self):
        self.workspace("main", self.owner / "src/Service")
        worktrees.open_worktree(self.selected)
        self.assert_open(self.owner / "src/Service", self.task / "src/Service")

    def test_first_task_also_uses_the_main_package(self):
        worktrees.open_worktree(self.selected)
        self.assert_open(self.owner / "src/Service", self.task / "src/Service")

    def test_existing_cdk_parent_does_not_override_main_package(self):
        self.workspace("cdk", self.owner / "src/ServiceCDK")
        self.workspace("main", self.owner / "src/Service")
        worktrees.open_worktree(self.selected)
        self.assert_open(self.owner / "src/Service", self.task / "src/Service")

    def test_differently_named_workspace_uses_existing_parent(self):
        parent = self.owner / "src/Service"
        target = self.task / "src/Service"
        parent.rename(parent.with_name("Application"))
        target.rename(target.with_name("Application"))
        self.workspace("main", parent.with_name("Application"))
        worktrees.open_worktree(self.selected)
        self.assert_open(parent.with_name("Application"), target.with_name("Application"))

    def test_another_brazil_workspace_cannot_supply_the_parent(self):
        (self.task / "src/Service/.git").unlink()
        self.workspace("other", self.root / "Other/src/ServiceCDK")
        worktrees.open_worktree(self.selected)
        self.assert_open(self.selected["parent"], self.selected["path"])

    def test_missing_main_package_opens_task_without_an_extra_parent(self):
        (self.task / "src/Service/.git").unlink()
        self.workspace("main", self.owner / "src/Service")
        worktrees.open_worktree(self.selected)
        self.run.assert_called_once_with(
            ["herdr", "workspace", "create", "--cwd", str(self.task),
             "--label", self.task.name, "--focus"],
            check=True,
        )

    def test_existing_task_under_sibling_package_is_focused(self):
        self.workspace("task", self.task / "src/Service", linked=True)
        worktrees.open_worktree(self.selected)
        self.run.assert_called_once_with(["herdr", "workspace", "focus", "task"], check=True)

    def test_existing_task_root_shell_is_focused(self):
        self.panes.append({"cwd": str(self.task), "tab_id": "task:tab"})
        worktrees.open_worktree(self.selected)
        self.run.assert_called_once_with(["herdr", "tab", "focus", "task:tab"], check=True)

    def test_another_linked_task_does_not_replace_the_new_task(self):
        other = self.owner / "worktrees/other"
        other.mkdir(parents=True)
        (other / "packageInfo").touch()
        self.workspace("other-task", other / "src/Service", linked=True)
        worktrees.open_worktree(self.selected)
        self.assert_open(self.owner / "src/Service", self.task / "src/Service")

    def test_standalone_git_checkout_keeps_native_open(self):
        with patch.object(worktrees, "brazil_workspace", return_value=None):
            worktrees.open_worktree(self.selected)
        self.assert_open(self.selected["parent"], self.selected["path"])


if __name__ == "__main__":
    unittest.main()
