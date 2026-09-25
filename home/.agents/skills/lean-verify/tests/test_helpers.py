"""Behavior checks using disposable Git repositories and the real Lean toolchain."""

import hashlib
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"


def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


scope = load("scope")
checker = load("check")
LAKE = os.environ.get("LEAN_VERIFY_LAKE") or shutil.which("lake")


class ScopeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lean-scope-test-")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.git("init", "-q")
        # Import fixture history without staging/committing any user's files.
        fixture = (
            b"blob\nmark :1\ndata 4\nold\n\n"
            b"commit refs/heads/main\nmark :2\n"
            b"committer Fixture <fixture@example.invalid> 1 +0000\n"
            b"data 8\nfixture\n\nM 100644 :1 source.ts\n\n"
        )
        self.git("fast-import", "--quiet", data=fixture)
        self.git("symbolic-ref", "HEAD", "refs/heads/main")
        self.git("read-tree", "HEAD")
        self.git("checkout-index", "--all")

    def git(self, *args, data=None):
        return subprocess.run(["git", "-C", str(self.repo), *args], input=data,
                              check=True, capture_output=True).stdout

    def stage_fixture(self, path, content):
        blob = self.git("hash-object", "-w", "--stdin", data=content).decode().strip()
        self.git("update-index", "--add", "--cacheinfo", f"100644,{blob},{path}")

    def test_staged_and_unstaged_use_current_bytes_even_when_net_diff_is_empty(self):
        self.stage_fixture("source.ts", b"staged\n")
        result = scope.snapshot(self.repo, "uncommitted")
        self.assertEqual(result["files"], [{
            "path": "source.ts", "changes": ["staged", "unstaged"],
            "kind": "file", "sha256": hashlib.sha256(b"old\n").hexdigest(),
        }])

    def test_clean_worktree_has_no_uncommitted_candidates(self):
        self.assertEqual(scope.snapshot(self.repo, "uncommitted")["files"], [])
        self.assertEqual(len(scope.snapshot(self.repo, "all")["files"]), 1)

    def test_untracked_names_ignored_files_and_clean_all_scope(self):
        (self.repo / "untracked space\nname.ts").write_bytes(b"new")
        (self.repo / ".gitignore").write_text("ignored.ts\n")
        (self.repo / "ignored.ts").write_text("ignored")
        changed = scope.snapshot(self.repo, "uncommitted")
        names = {f["path"] for f in changed["files"]}
        self.assertEqual(names, {".gitignore", "untracked space\nname.ts"})
        self.assertIn("source.ts", {f["path"] for f in scope.snapshot(self.repo, "all")["files"]})

    def test_rename_keeps_deleted_and_new_paths(self):
        (self.repo / "source.ts").rename(self.repo / "renamed.ts")
        self.git("update-index", "--remove", "source.ts")
        self.stage_fixture("renamed.ts", b"old\n")
        files = {f["path"]: f for f in scope.snapshot(self.repo, "uncommitted")["files"]}
        self.assertEqual(set(files), {"source.ts", "renamed.ts"})
        self.assertEqual(files["source.ts"]["kind"], "deleted")

    def test_symlink_is_not_followed_and_scan_leaves_index_unchanged(self):
        (self.repo / "external.ts").symlink_to("/not/a/readable/source.ts")
        before = (self.repo / ".git/index").read_bytes()
        result = scope.snapshot(self.repo, "uncommitted")
        self.assertEqual(result["files"][0]["kind"], "symlink")
        self.assertEqual((self.repo / ".git/index").read_bytes(), before)

    def test_new_repository_without_head(self):
        empty = self.repo / "new-repo"
        empty.mkdir()
        subprocess.run(["git", "-C", str(empty), "init", "-q"], check=True)
        (empty / "new.go").write_text("package new\n")
        result = scope.snapshot(empty, "uncommitted")
        self.assertIsNone(result["head"])
        self.assertEqual(result["files"][0]["path"], "new.go")


@unittest.skipUnless(LAKE, "Set LEAN_VERIFY_LAKE to run real Lean checks")
class ProofTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lean-proof-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "proof"
        self.project.mkdir()
        self.project.joinpath("lakefile.toml").write_text(
            'name = "verification"\nversion = "0.1.0"\n'
            'defaultTargets = ["Verification"]\n\n'
            '[[lean_lib]]\nname = "Verification"\n'
        )
        version = subprocess.run([LAKE, "env", "lean", "--short-version"],
                                 cwd=self.project, check=True, text=True,
                                 capture_output=True).stdout.strip()
        self.project.joinpath("lean-toolchain").write_text(f"leanprover/lean4:v{version}\n")

    def check(self, source, theorem="Verification.claim", lake=LAKE):
        self.project.joinpath("Verification.lean").write_text(source)
        return checker.check(self.project, "Verification", [theorem],
                             self.root / "evidence", lake, 60)

    def test_real_proof_is_checked_with_statement_and_hashes(self):
        result = self.check(
            "theorem Verification.claim (n : Nat) : n + 0 = n := by rfl\n")
        self.assertEqual(result["status"], "checked", result)
        self.assertIn("n + 0 = n", result["theorems"][0]["statement"])
        self.assertIn("Verification.lean", result["sources"])

    def test_sorry_is_rejected(self):
        result = self.check("theorem Verification.claim : False := by sorry\n")
        self.assertEqual(result["status"], "rejected", result)
        self.assertIn("sorryAx", result["theorems"][0]["unexpected_axioms"])

    def test_custom_axiom_is_rejected(self):
        result = self.check(
            "axiom unjustified : False\ntheorem Verification.claim : False := unjustified\n")
        self.assertEqual(result["status"], "rejected", result)
        self.assertIn("unjustified", result["theorems"][0]["unexpected_axioms"])

    def test_imported_incomplete_proof_is_rejected_transitively(self):
        self.project.joinpath("Verification").mkdir()
        self.project.joinpath("Verification/Helper.lean").write_text(
            "theorem hiddenGap : False := by sorry\n")
        result = self.check(
            "import Verification.Helper\ntheorem Verification.claim : False := hiddenGap\n")
        self.assertEqual(result["status"], "rejected", result)
        self.assertIn("sorryAx", result["theorems"][0]["unexpected_axioms"])

    def test_native_evaluation_is_rejected(self):
        result = self.check(
            "import Std\ntheorem Verification.claim : 2 + 2 = 4 := by native_decide\n")
        self.assertEqual(result["status"], "rejected", result)
        self.assertTrue(result["theorems"][0]["unexpected_axioms"])

    def test_definition_cannot_masquerade_as_theorem(self):
        result = self.check("def Verification.claim : Nat := 1\n")
        self.assertEqual(result["status"], "blocked")
        self.assertIn("Expected a theorem", (self.root / "evidence/audit.log").read_text())

    def test_false_property_is_not_reported_as_checked(self):
        result = self.check("theorem Verification.claim : 0 = 1 := by decide\n")
        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["theorems"], [])

    def test_missing_tool_still_writes_evidence(self):
        result = self.check("", lake=None)
        self.assertEqual(result["status"], "blocked")
        self.assertTrue((self.root / "evidence/evidence.json").exists())

    def test_mismatched_toolchain_is_blocked(self):
        self.project.joinpath("lean-toolchain").write_text("leanprover/lean4:v0.0.0\n")
        result = self.check("theorem Verification.claim : True := trivial\n")
        self.assertEqual(result["status"], "blocked")
        self.assertIn("does not match", result["error"])

    def test_timeout_stops_child_processes_and_keeps_partial_log(self):
        fake = self.root / "fake-lake"
        fake.write_text(
            "#!/usr/bin/env python3\nimport subprocess, sys, time\n"
            "subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])\n"
            "print('started', flush=True)\ntime.sleep(60)\n")
        fake.chmod(0o755)
        started = time.monotonic()
        result = checker.check(self.project, "Verification", ["Verification.claim"],
                               self.root / "timeout", str(fake), 1)
        self.assertLess(time.monotonic() - started, 5)
        self.assertEqual(result["status"], "blocked")
        self.assertIn("timed out", result["error"])
        self.assertIn("started", (self.root / "timeout/version.log").read_text())


if __name__ == "__main__":
    unittest.main()
