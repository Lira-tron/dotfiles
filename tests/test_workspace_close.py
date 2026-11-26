import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("workspace_close", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


def workspace(identifier, label, repo_key=None, linked=False):
    result = {"workspace_id": identifier, "label": label}
    if repo_key:
        result["worktree"] = {
            "repo_key": repo_key, "is_linked_worktree": linked,
            "checkout_path": f"/fixture/{identifier}",
        }
    return result


class WorkspaceCloseTests(unittest.TestCase):
    def setUp(self):
        self.parent = workspace("parent", "src", "repo")
        self.linked = workspace("linked", "src", "repo", linked=True)
        self.unrelated = workspace("unrelated", "src", "other")
        self.workspaces = [self.parent, self.linked, self.unrelated]
        self.output = self.enterContext(contextlib.redirect_stderr(io.StringIO()))
        self.query = self.enterContext(patch.object(
            worktrees.subprocess, "check_output", side_effect=self.snapshot,
        ))
        self.run = self.enterContext(patch.object(worktrees.subprocess, "run"))
        self.prompt = self.enterContext(patch.object(worktrees, "prompt", return_value="ok"))

    def snapshot(self, command):
        self.assertEqual(command, ["herdr", "api", "snapshot"])
        return json.dumps({"result": {"snapshot": {"workspaces": self.workspaces}}}).encode()

    def test_ordinary_workspace_closes_without_group_confirmation(self):
        self.workspaces = [workspace("ordinary", "src")]
        worktrees.close_workspace("ordinary")
        self.prompt.assert_not_called()
        self.run.assert_called_once_with(
            ["herdr", "workspace", "close", "ordinary"], check=True,
        )

    def test_linked_workspace_closes_without_closing_its_parent(self):
        worktrees.close_workspace("linked")
        self.prompt.assert_not_called()
        self.run.assert_called_once_with(
            ["herdr", "workspace", "close", "linked"], check=True,
        )

    def test_group_confirmation_lists_only_members_and_closes_group(self):
        worktrees.close_workspace("parent")
        self.prompt.assert_called_once_with(
            "Type ok to close these workspaces (blank cancels): "
        )
        self.assertIn("/fixture/parent", self.output.getvalue())
        self.assertIn("/fixture/linked", self.output.getvalue())
        self.assertNotIn("/fixture/unrelated", self.output.getvalue())
        self.run.assert_called_once_with(
            ["herdr", "workspace", "close", "parent", "--group"], check=True,
        )

    def test_cancelling_keeps_entire_group_open(self):
        for answer in ["", "yes", "OK", "parent"]:
            with self.subTest(answer=answer):
                self.prompt.return_value = answer
                worktrees.close_workspace("parent")
                self.run.assert_not_called()

    def test_group_change_requires_a_new_confirmation(self):
        def confirm(_):
            self.workspaces.append(workspace("new-member", "new", "repo", linked=True))
            return "ok"

        self.prompt.side_effect = confirm
        with self.assertRaisesRegex(ValueError, "group changed"):
            worktrees.close_workspace("parent")
        self.run.assert_not_called()

    def test_missing_workspace_cannot_close_another_with_same_label(self):
        with self.assertRaisesRegex(ValueError, "no longer exists"):
            worktrees.close_workspace("missing")
        self.prompt.assert_not_called()
        self.run.assert_not_called()

    def test_cli_uses_workspace_id_without_decoding_a_worktree_token(self):
        with (
            patch.object(sys, "argv", [str(SOURCE), "close-workspace", "linked"]),
            patch.object(worktrees, "close_workspace") as close,
            patch.object(worktrees, "delete_worktree") as delete,
        ):
            worktrees.main()
        close.assert_called_once_with("linked")
        delete.assert_not_called()

    def test_native_close_failure_is_not_reported_as_success(self):
        self.run.side_effect = subprocess.CalledProcessError(1, ["herdr"])
        with self.assertRaises(subprocess.CalledProcessError):
            worktrees.close_workspace("linked")


if __name__ == "__main__":
    unittest.main()
