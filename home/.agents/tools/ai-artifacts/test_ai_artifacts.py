import contextlib
from datetime import datetime, timezone
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("ai_artifacts", Path(__file__).with_name("ai_artifacts.py"))
artifacts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(artifacts)


class ArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.checkout = self.root / "checkout"
        self.checkout.mkdir()
        self.knowledge = self.root / "knowledge" / "ai" / "artifacts"
        self.home_patch = patch.object(artifacts.Path, "home", return_value=self.root)
        self.home_patch.start()
        self.addCleanup(self.home_patch.stop)

    def init(self, feature="one-feature", created="26-10-19", package="ExamplePackage"):
        return artifacts.initialize(self.checkout, package, feature, created)

    def test_directory_link_writes_survive_checkout_removal(self):
        target = self.init()
        self.assertEqual(target, self.knowledge / "ExamplePackage" / "26-10-19-one-feature")
        self.assertTrue((self.checkout / ".ai").is_symlink())
        note = self.checkout / ".ai" / "spec.md"
        note.write_text("retained specification")
        (self.checkout / ".ai").unlink()
        self.checkout.rmdir()
        self.assertEqual((target / "spec.md").read_text(), "retained specification")

    def test_resume_keeps_creation_date_and_existing_data(self):
        target = self.init(created="25-12-31")
        (target / "spec.md").write_text("original")
        self.assertEqual(artifacts.initialize(self.checkout, "ExamplePackage", "one-feature"), target)
        self.assertEqual(artifacts.selected_path(self.checkout, "ExamplePackage"), target)
        self.assertEqual((target / "spec.md").read_text(), "original")

    def test_commands_reject_feature_directories_outside_artifact_root(self):
        target = self.knowledge.parent / "ExamplePackage" / "25-12-31-one-feature"
        target.mkdir(parents=True)
        (target / "spec.md").write_text("original")
        (self.checkout / ".ai").symlink_to(target, target_is_directory=True)
        for command in ["init", "path", "contains"]:
            error = io.StringIO()
            args = [command, "--cwd", str(self.checkout)]
            if command == "contains":
                args += ["--file", ".ai/spec.md"]
            with self.subTest(command=command), contextlib.redirect_stderr(error):
                status = artifacts.main(args)
                self.assertEqual(status, 1)
                self.assertIn("under ~/knowledge/ai/artifacts/", error.getvalue())
        self.assertEqual((self.checkout / ".ai").readlink(), target)
        self.assertEqual((target / "spec.md").read_text(), "original")
        self.assertFalse(self.knowledge.exists())

    def test_new_link_ignores_directories_outside_artifact_root(self):
        unrelated = self.knowledge.parent / "ExamplePackage" / "26-10-19-one-feature"
        unrelated.mkdir(parents=True)
        (unrelated / "spec.md").write_text("unrelated")
        target = self.init()
        self.assertEqual(target, self.knowledge / "ExamplePackage" / "26-10-19-one-feature")
        self.assertFalse((target / "spec.md").exists())
        self.assertEqual((unrelated / "spec.md").read_text(), "unrelated")

    def test_new_link_uses_utc_creation_date(self):
        target = self.init(created=None)
        self.assertEqual(target.name, datetime.now(timezone.utc).strftime("%y-%m-%d") + "-one-feature")

    def test_separate_features_get_separate_targets(self):
        first = self.init()
        other = self.root / "other"
        other.mkdir()
        second = artifacts.initialize(other, "ExamplePackage", "another-feature", "26-10-19")
        self.assertNotEqual(first, second)
        (first / "private-note.md").write_text("feature one")
        self.assertFalse((other / ".ai" / "private-note.md").exists())

    def test_existing_date_can_be_reattached_without_overwriting(self):
        target = self.init()
        (target / "spec.md").write_text("saved")
        (self.checkout / ".ai").unlink()
        self.assertEqual(self.init(), target)
        self.assertEqual((target / "spec.md").read_text(), "saved")

    def test_explicit_package_override_is_retained_on_resume(self):
        target = self.init(package="ExplicitOwner")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            status = artifacts.main(["path", "--cwd", str(self.checkout)])
        self.assertEqual(status, 0)
        self.assertEqual(Path(output.getvalue().strip()), target)
        self.assertEqual(artifacts.initialize(self.checkout), target)

    def test_physical_directory_is_preserved(self):
        link = self.checkout / ".ai"
        link.mkdir()
        (link / "spec.md").write_text("legacy")
        with self.assertRaisesRegex(ValueError, "Preserve and migrate"):
            self.init()
        self.assertEqual((link / "spec.md").read_text(), "legacy")
        self.assertFalse(self.knowledge.exists())

    def test_existing_feature_package_and_date_cannot_change(self):
        target = self.init()
        for kwargs in [
            {"feature": "another"}, {"package": "OtherPackage"}, {"created": "26-10-20"},
        ]:
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                self.init(**kwargs)
        self.assertEqual((self.checkout / ".ai").resolve(), target)

    def test_link_must_target_exact_feature_directory(self):
        outside = self.root / "outside"
        for target in [
            outside, self.knowledge.parent, self.knowledge.parent / "ExamplePackage",
            self.knowledge, self.knowledge / "ExamplePackage",
            self.knowledge / "26-10-19-one-feature",
        ]:
            target.mkdir(parents=True, exist_ok=True)
            link = self.checkout / ".ai"
            link.symlink_to(target, target_is_directory=True)
            with self.subTest(target=target), self.assertRaises(ValueError):
                artifacts.selected_path(self.checkout)
            link.unlink()

    def test_dangling_link_is_preserved(self):
        link = self.checkout / ".ai"
        link.symlink_to(self.knowledge / "ExamplePackage" / "26-10-19-one-feature")
        with self.assertRaises(FileNotFoundError):
            self.init()
        self.assertTrue(link.is_symlink())
        self.assertFalse(self.knowledge.exists())

    def test_package_or_feature_symlinks_cannot_escape_or_alias(self):
        self.knowledge.mkdir(parents=True)
        outside = self.root / "outside"
        outside.mkdir()
        package = self.knowledge / "ExamplePackage"
        package.symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "redirect"):
            self.init()
        package.unlink()
        package.mkdir()
        (package / "26-10-19-one-feature").symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "redirect"):
            self.init()
        self.assertFalse((self.checkout / ".ai").exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_unsafe_components_and_invalid_dates_create_nothing(self):
        for kwargs in [
            {"feature": "../other"}, {"feature": "/other"}, {"feature": "a/b"},
            {"feature": "bad name"}, {"package": ".."}, {"package": "/other"},
            {"package": "a/b"}, {"created": "26-02-30"}, {"created": "2026-10-19"},
        ]:
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                self.init(**kwargs)
            self.assertFalse(self.knowledge.exists())

    def test_path_command_does_not_initialize(self):
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            status = artifacts.main(["path", "--cwd", str(self.checkout), "--package", "ExamplePackage"])
        self.assertEqual(status, 1)
        self.assertIn("No feature link", stderr.getvalue())
        self.assertFalse(self.knowledge.exists())

    def test_contains_checks_only_the_selected_feature_and_resolves_links(self):
        target = self.init()
        outside = self.root / "source.py"
        outside.write_text("source")
        (target / "linked.py").symlink_to(outside)
        for candidate, expected in [
            (str(target / "new-note.md"), 0),
            (".ai/new-note.md", 0),
            (str(self.knowledge / "ExamplePackage/26-10-19-another/note.md"), 1),
            (str(outside), 1),
            (".ai/linked.py", 1),
            (".ai/../source.py", 1),
        ]:
            with self.subTest(candidate=candidate):
                status = artifacts.main(["contains", "--cwd", str(self.checkout), "--file", candidate])
                self.assertEqual(status, expected)

    def test_config_package_and_nested_git_root(self):
        subprocess.run(["git", "init", "-q", str(self.checkout)], check=True)
        (self.checkout / "Config").write_text("# ignored\npackage.ExamplePackage = {\n};\n")
        nested = self.checkout / "src"
        nested.mkdir()
        self.assertEqual(artifacts.checkout_root(nested), self.checkout)
        self.assertEqual(artifacts.package_name(self.checkout), "ExamplePackage")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            status = artifacts.main([
                "init", "--cwd", str(nested), "--feature", "one-feature", "--date", "26-10-19",
            ])
        self.assertEqual(status, 0)
        self.assertEqual(Path(output.getvalue().strip()), self.init())
        self.assertFalse((nested / ".ai").exists())

    def test_standalone_repository_name_is_used_without_config(self):
        self.assertEqual(artifacts.package_name(self.checkout), "checkout")


if __name__ == "__main__":
    unittest.main()
