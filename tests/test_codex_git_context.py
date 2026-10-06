import runpy
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace


SOURCE = Path(__file__).resolve().parents[1] / "home/.codex/git-context.py"
CONTEXT = SimpleNamespace(**runpy.run_path(str(SOURCE)))


def git(root, *arguments, text=None):
    return subprocess.check_output(
        [
            "git",
            "-C",
            str(root),
            "-c",
            "user.name=Fixture",
            "-c",
            "user.email=fixture@example.invalid",
            *arguments,
        ],
        input=text,
        text=True,
        stderr=subprocess.PIPE,
    ).strip()


def commit_file(root, branch, contents, parent=None):
    blob = git(root, "hash-object", "-w", "--stdin", text=contents)
    tree = git(root, "mktree", text=f"100644 blob {blob}\tfile.txt\n")
    arguments = ["commit-tree", tree, "-m", "Fixture"]
    if parent:
        arguments.extend(["-p", parent])
    commit = git(root, *arguments)
    git(root, "update-ref", f"refs/heads/{branch}", commit)
    return commit


def repository(root, contents="one\ntwo\nthree\n"):
    root.mkdir(parents=True)
    git(root, "init", "--initial-branch=main")
    base = commit_file(root, "main", "one\n")
    head = commit_file(root, "feature", contents, base)
    git(root, "symbolic-ref", "HEAD", "refs/heads/feature")
    return head


class GitContextTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def test_ordinary_checkout_uses_branch_and_committed_changes(self):
        root = self.root / "repo"
        repository(root)
        (root / "file.txt").write_text("uncommitted content\n")
        self.assertEqual("b:feature", CONTEXT.label(root))
        self.assertEqual({"additions": 2, "deletions": 0}, CONTEXT.changes(root))

    def test_linked_worktree_uses_directory_name(self):
        root = self.root / "repo"
        repository(root)
        linked = self.root / "worktree-name"
        git(root, "worktree", "add", "-b", "different-branch", str(linked), "feature")
        self.assertEqual("w:worktree-name", CONTEXT.label(linked))
        self.assertEqual({"additions": 2, "deletions": 0}, CONTEXT.changes(linked))

    def test_brazil_parent_totals_packages_and_package_view_stays_scoped(self):
        workspace = self.root / "brazil-task"
        first = workspace / "src/First"
        second = workspace / "src/Second"
        repository(first)
        repository(second, "replacement\nsecond\n")
        (workspace / "packageInfo").write_text('worktree = "true";\n')
        self.assertEqual("w:brazil-task", CONTEXT.label(workspace))
        self.assertEqual("w:brazil-task", CONTEXT.label(first))
        self.assertEqual({"additions": 4, "deletions": 1}, CONTEXT.changes(workspace))
        self.assertEqual({"additions": 2, "deletions": 0}, CONTEXT.changes(first))
        self.assertEqual(
            {"additions": 4, "deletions": 1}, CONTEXT.changes(workspace / "src")
        )

    def test_missing_package_base_does_not_report_partial_totals(self):
        workspace = self.root / "brazil-task"
        repository(workspace / "src/First")
        second = workspace / "src/Second"
        repository(second)
        git(second, "update-ref", "-d", "refs/heads/main")
        (workspace / "packageInfo").write_text('worktree = "true";\n')
        self.assertIsNone(CONTEXT.changes(workspace))

    def test_remote_default_takes_precedence_over_stale_local_main(self):
        root = self.root / "repo"
        head = repository(root)
        git(root, "remote", "add", "origin", "https://example.invalid/repo.git")
        git(root, "update-ref", "refs/remotes/origin/main", head)
        git(root, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")
        self.assertEqual({"additions": 0, "deletions": 0}, CONTEXT.changes(root))

    def test_unrelated_directory_has_no_git_footer(self):
        self.assertEqual("", CONTEXT.label(self.root))
        self.assertIsNone(CONTEXT.changes(self.root))


if __name__ == "__main__":
    unittest.main()
