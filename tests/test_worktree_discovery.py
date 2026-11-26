import base64
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


# Keep the worker checkout when the mutation runner links the test directory.
SOURCE = Path(__file__).absolute().parents[1] / "home/.config/rex/worktrees.py"
spec = importlib.util.spec_from_file_location("worktree_discovery", SOURCE)
worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worktrees)


class WorkspacePickerTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory())).resolve()
        self.owner = self.root / "Service"
        self.full = self.owner / "worktrees/full"
        self.partial = self.owner / "worktrees/partial"
        for workspace, packages in [
            (self.owner, ["Service", "ServiceCDK"]),
            (self.full, ["Service", "ServiceCDK"]),
            (self.partial, ["ServiceCDK"]),
        ]:
            workspace.mkdir(parents=True)
            (workspace / "packageInfo").touch()
            for name in packages:
                repo = workspace / "src" / name
                repo.mkdir(parents=True)
                (repo / ".git").touch()
        (self.owner / "src/not-a-repository").mkdir()
        self.enterContext(patch.object(worktrees, "checkouts", side_effect=self.checkouts))

    def checkouts(self, repo):
        return [
            {"worktree": str(workspace / "src" / repo.name)}
            for workspace in [self.owner, self.full, self.partial]
            if (workspace / "src" / repo.name / ".git").exists()
        ]

    def test_every_workspace_location_lists_sibling_packages_worktrees_once(self):
        for caller in [
            self.owner, self.owner / "src", self.owner / "src/Service",
            self.owner / "worktrees", self.full, self.full / "src",
            self.full / "src/Service", self.partial / "src/ServiceCDK",
        ]:
            with self.subTest(caller=caller):
                entries = worktrees.current_rows(caller)
                paths = [
                    Path(json.loads(base64.urlsafe_b64decode(row.split("\t")[1]))["path"])
                    for row in entries
                ]
                self.assertCountEqual(
                    [path.parent.parent for path in paths], [self.full, self.partial],
                )

    def test_empty_brazil_workspace_does_not_list_a_neighboring_workspaces_trees(self):
        empty = self.root / "Empty"
        (empty / "src").mkdir(parents=True)
        (empty / "packageInfo").touch()
        self.assertEqual(worktrees.current_rows(empty / "src"), [])

    def test_workspace_discovery_keeps_git_worktrees_outside_the_workspace(self):
        external = self.root / "external"
        external.mkdir()
        records = [
            {"worktree": str(self.owner / "src/Service")},
            {"worktree": str(external)},
        ]
        with (
            patch.object(worktrees, "repositories", return_value=[self.owner / "src/Service"]),
            patch.object(worktrees, "checkouts", return_value=records),
        ):
            entries = worktrees.current_rows(self.owner / "src")
        self.assertEqual(len(entries), 1)
        selected = json.loads(base64.urlsafe_b64decode(entries[0].split("\t")[1]))
        self.assertEqual(selected["path"], str(external))

    def test_standalone_git_directory_keeps_nearest_scope_discovery(self):
        standalone = self.root / "standalone"
        standalone.mkdir()
        with patch.object(worktrees, "workplace_rows", return_value=["standalone-tree"]) as rows:
            self.assertEqual(worktrees.current_rows(standalone), ["standalone-tree"])
        rows.assert_called_once_with(standalone, restrict_paths=False)

    def test_independent_workspace_keeps_its_own_scope(self):
        for independent in [
            self.owner / "nested/Independent", self.root / "worktrees/Independent",
        ]:
            with self.subTest(workspace=independent):
                independent.mkdir(parents=True)
                (independent / "packageInfo").touch()
                with patch.object(worktrees, "workplace_rows", return_value=[]) as rows:
                    self.assertEqual(worktrees.current_rows(independent), [])
                rows.assert_called_once_with(independent, restrict_paths=False)

    def test_workspace_and_src_creation_use_the_primary_workspace(self):
        earlier = self.owner / "src/AlphabeticalFirst"
        earlier.mkdir()
        (earlier / ".git").touch()
        for caller in [
            self.owner, self.owner / "src", self.owner / "worktrees",
            self.full, self.full / "src", self.partial, self.partial / "src",
        ]:
            with self.subTest(caller=caller):
                with (
                    patch.object(worktrees.sys, "argv", [str(SOURCE), "create-current"]),
                    patch.object(worktrees.Path, "cwd", return_value=caller),
                    patch.object(
                        worktrees.subprocess, "check_output",
                        side_effect=subprocess.CalledProcessError(
                            1, ["brazil-context", "package", "root"],
                            stderr=b"Directory isn't within a package",
                        ),
                    ),
                    patch.object(worktrees, "create_worktree", return_value=None) as create,
                ):
                    worktrees.main()
                parent = str(self.owner / "src/Service")
                create.assert_called_once_with({"parent": parent, "path": parent})

    def test_package_creation_preserves_the_callers_package_and_uses_its_primary_checkout(self):
        caller = self.partial / "src/ServiceCDK"
        with patch.object(worktrees.subprocess, "check_output", return_value=str(caller).encode()):
            self.assertEqual(
                worktrees.current_parent(caller), str(self.owner / "src/ServiceCDK"),
            )

    def test_creation_outside_a_brazil_workspace_keeps_the_original_error(self):
        error = subprocess.CalledProcessError(
            1, ["brazil-context", "package", "root"], stderr=b"Directory isn't within a package",
        )
        with (
            patch.object(worktrees.subprocess, "check_output", side_effect=error),
            self.assertRaises(subprocess.CalledProcessError) as raised,
        ):
            worktrees.current_parent(self.root)
        self.assertIs(raised.exception, error)

    def test_workspace_without_matching_package_uses_an_existing_package(self):
        (self.owner / "src/Service/.git").unlink()
        with (
            patch.object(worktrees.sys, "argv", [str(SOURCE), "create-current"]),
            patch.object(worktrees.Path, "cwd", return_value=self.owner),
            patch.object(
                worktrees.subprocess, "check_output",
                side_effect=subprocess.CalledProcessError(1, ["brazil-context"]),
            ),
            patch.object(worktrees, "create_worktree", return_value=None) as create,
        ):
            worktrees.main()
        parent = str(self.owner / "src/ServiceCDK")
        create.assert_called_once_with({"parent": parent, "path": parent})

    def test_workspace_with_no_git_packages_cannot_create_a_worktree(self):
        empty = self.root / "Empty"
        (empty / "src/not-a-repository").mkdir(parents=True)
        (empty / "packageInfo").touch()
        with (
            patch.object(worktrees.sys, "argv", [str(SOURCE), "create-current"]),
            patch.object(worktrees.Path, "cwd", return_value=empty),
            patch.object(
                worktrees.subprocess, "check_output",
                side_effect=subprocess.CalledProcessError(1, ["brazil-context"]),
            ),
            patch.object(worktrees, "create_worktree") as create,
            self.assertRaisesRegex(ValueError, "No Git packages"),
        ):
            worktrees.main()
        create.assert_not_called()


if __name__ == "__main__":
    unittest.main()
