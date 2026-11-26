import importlib.util
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).absolute().parents[1] / "home/.config/television/cable/rex-worktrees.py"
spec = importlib.util.spec_from_file_location("rex_worktrees", SOURCE)
rex_worktrees = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rex_worktrees)

SESSION = "session:01a20c35-252f-79b4-a4be-3d98f4dc39e1"


class RexSessionActionTests(unittest.TestCase):
    def setUp(self):
        self.prompt = self.enterContext(patch.object(rex_worktrees.worktrees, "prompt"))
        self.kill = self.enterContext(patch.object(rex_worktrees, "kill_sessions"))
        self.open = self.enterContext(patch.object(rex_worktrees, "open_session"))
        self.create_worktree = self.enterContext(
            patch.object(rex_worktrees.worktrees, "create_worktree")
        )
        self.enterContext(patch.object(
            rex_worktrees, "sessions", return_value=[{"session_id": SESSION, "label": "work"}],
        ))
        self.enterContext(patch.object(rex_worktrees, "pick_server", return_value="lyhost"))

    def test_delete_session_closes_after_ok(self):
        # Given
        self.prompt.return_value = "ok"
        # When
        rex_worktrees.delete(SESSION, force=False)
        # Then
        self.kill.assert_called_once_with([SESSION])

    def test_delete_session_keeps_it_without_ok(self):
        # Given
        self.prompt.return_value = ""
        # When
        rex_worktrees.delete(SESSION, force=False)
        # Then
        self.kill.assert_not_called()

    def test_force_delete_session_closes_without_asking(self):
        # When
        rex_worktrees.delete(SESSION, force=True)
        # Then
        self.prompt.assert_not_called()
        self.kill.assert_called_once_with([SESSION])

    def test_create_on_session_opens_named_session_on_picked_host(self):
        # Given
        self.prompt.return_value = "review"
        # When
        rex_worktrees.create(SESSION)
        # Then
        self.open.assert_called_once_with(Path.cwd(), "review", "lyhost")
        self.create_worktree.assert_not_called()

    def test_create_on_session_with_blank_name_does_nothing(self):
        # Given
        self.prompt.return_value = ""
        # When
        rex_worktrees.create(SESSION)
        # Then
        self.open.assert_not_called()
        self.create_worktree.assert_not_called()


class RexOpenSessionTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(rex_worktrees.sys, "platform", "darwin"))
        self.select = self.enterContext(patch.object(rex_worktrees, "select"))
        self.rex_json = self.enterContext(
            patch.object(rex_worktrees, "rex_json", return_value={"session_id": SESSION})
        )

    def test_open_session_reuses_session_with_label(self):
        # Given
        self.enterContext(patch.object(rex_worktrees, "labelled", return_value=[SESSION]))
        # When
        rex_worktrees.open_session(Path("/tmp"), "review")
        # Then
        self.rex_json.assert_not_called()
        self.select.assert_called_once_with(SESSION, None)

    def test_open_session_creates_local_session_in_directory(self):
        # Given
        labelled = self.enterContext(patch.object(rex_worktrees, "labelled", return_value=[]))
        # When
        rex_worktrees.open_session(Path("/tmp"), "review")
        # Then
        labelled.assert_called_once_with("review", None)
        self.rex_json.assert_called_once_with("new", "review", "-c", "/tmp")
        self.select.assert_called_once_with(SESSION, None)

    def test_open_session_on_remote_host_starts_in_its_home(self):
        # Given
        labelled = self.enterContext(patch.object(rex_worktrees, "labelled", return_value=[]))
        # When
        rex_worktrees.open_session(Path("/tmp"), "review", "lyhost")
        # Then
        labelled.assert_called_once_with("🥊-review", "lyhost")
        self.rex_json.assert_called_once_with("-S", "lyhost", "new", "🥊-review")
        self.select.assert_called_once_with(SESSION, "lyhost")

    def test_open_session_defaults_label_to_directory_name(self):
        # Given
        labelled = self.enterContext(patch.object(rex_worktrees, "labelled", return_value=[]))
        # When
        rex_worktrees.open_session(Path("/tmp"))
        # Then
        labelled.assert_called_once_with(rex_worktrees.session_name(Path("/tmp")), None)

    def test_worktree_sessions_get_the_marker_and_reuse_matching_sessions(self):
        for platform, label in (("darwin", "🌴-tmp"), ("linux", "🥊🌴-tmp")):
            with (
                self.subTest(platform=platform),
                patch.object(rex_worktrees.sys, "platform", platform),
                patch.object(rex_worktrees, "labelled", return_value=[]) as labelled,
            ):
                self.rex_json.reset_mock()
                rex_worktrees.open_session(Path("/tmp"), worktree=True)
                labelled.assert_called_once_with(label, None)
                self.rex_json.assert_called_once_with("new", label, "-c", "/tmp")
                self.rex_json.reset_mock()
                labelled.return_value = [SESSION]
                rex_worktrees.open_session(Path("/tmp"), worktree=True)
                self.rex_json.assert_not_called()


class RexSessionLabelTests(unittest.TestCase):
    def test_local_label_on_mac_has_no_prefix(self):
        with patch.object(rex_worktrees.sys, "platform", "darwin"):
            self.assertEqual(rex_worktrees.session_label("review", None), "review")

    def test_label_on_remote_server_gets_prefix(self):
        with patch.object(rex_worktrees.sys, "platform", "darwin"):
            self.assertEqual(rex_worktrees.session_label("review", "lyhost"), "🥊-review")

    def test_label_on_linux_host_gets_prefix(self):
        with patch.object(rex_worktrees.sys, "platform", "linux"):
            self.assertEqual(rex_worktrees.session_label("review", None), "🥊-review")

    def test_prefixed_label_is_not_prefixed_twice(self):
        with patch.object(rex_worktrees.sys, "platform", "linux"):
            self.assertEqual(rex_worktrees.session_label("🥊-review", "lyhost"), "🥊-review")

    def test_worktree_prefixes_are_correct_and_idempotent(self):
        for platform, server, expected in (
            ("darwin", None, "🌴-review"),
            ("darwin", "lyhost", "🥊🌴-review"),
            ("linux", None, "🥊🌴-review"),
        ):
            with self.subTest(platform=platform, server=server), patch.object(rex_worktrees.sys, "platform", platform):
                self.assertEqual(rex_worktrees.session_label("review", server, worktree=True), expected)
                self.assertEqual(rex_worktrees.session_label(expected, server, worktree=True), expected)


class RexPickServerTests(unittest.TestCase):
    def setUp(self):
        self.prompt = self.enterContext(patch.object(rex_worktrees.worktrees, "prompt"))
        self.hosts = [{"host": {"label": "lyhost"}}]
        self.enterContext(patch.object(
            rex_worktrees, "rex_json", side_effect=lambda *args: {"hosts": self.hosts},
        ))

    def test_no_remote_hosts_creates_locally_without_asking(self):
        # Given
        self.hosts = []
        # When
        server = rex_worktrees.pick_server()
        # Then
        self.assertIsNone(server)
        self.prompt.assert_not_called()

    def test_no_answers_create_locally(self):
        for answer in ["n", "no", "N", "No"]:
            with self.subTest(answer=answer):
                # Given
                self.prompt.return_value = answer
                # When / Then
                self.assertIsNone(rex_worktrees.pick_server())

    def test_blank_or_yes_with_one_host_picks_it(self):
        for answer in ["", "y", "yes", "Y", "lyhost"]:
            with self.subTest(answer=answer):
                # Given
                self.prompt.return_value = answer
                # When / Then
                self.assertEqual(rex_worktrees.pick_server(), "lyhost")

    def test_other_answer_is_rejected(self):
        # Given
        self.prompt.return_value = "maybe"
        # When / Then
        with self.assertRaisesRegex(ValueError, "Answer y or n, or name one of the Rex hosts: lyhost"):
            rex_worktrees.pick_server()

    def test_yes_with_several_hosts_needs_a_label(self):
        # Given
        self.hosts = [{"host": {"label": "lyhost"}}, {"host": {"label": "devbox"}}]
        self.prompt.return_value = "y"
        # When / Then
        with self.assertRaisesRegex(ValueError, "lyhost, devbox"):
            rex_worktrees.pick_server()

    def test_named_host_among_several_is_picked(self):
        # Given
        self.hosts = [{"host": {"label": "lyhost"}}, {"host": {"label": "devbox"}}]
        self.prompt.return_value = "devbox"
        # When / Then
        self.assertEqual(rex_worktrees.pick_server(), "devbox")


class RexServerArgsTests(unittest.TestCase):
    def test_local_has_no_server_flag(self):
        self.assertEqual(rex_worktrees.on(None), [])

    def test_remote_adds_server_flag(self):
        self.assertEqual(rex_worktrees.on("lyhost"), ["-S", "lyhost"])


class RexNamedWorktreeTests(unittest.TestCase):
    def test_native_name_reaches_worktree_creation_and_opens_result(self):
        selected = {"parent": "/workspace/src/Package", "path": "/workspace/worktrees/old/src/Package"}
        token = base64.urlsafe_b64encode(json.dumps(selected).encode()).decode()
        for value in (token, "none"):
            with (
                self.subTest(value=value),
                patch.object(rex_worktrees.worktrees, "current_parent", return_value=selected["parent"]),
                patch.object(rex_worktrees.worktrees, "create_worktree", return_value={"path": "/created"}) as create,
                patch.object(rex_worktrees.worktrees, "prompt", side_effect=AssertionError("No terminal prompt")),
                patch.object(rex_worktrees, "open_session") as open_session,
                patch.object(rex_worktrees.sys, "argv", [str(SOURCE), "create-named", value, "feature-work"]),
            ):
                rex_worktrees.main()
                expected = selected if value == token else {"parent": selected["parent"], "path": selected["parent"]}
                create.assert_called_once_with(expected, name="feature-work")
                open_session.assert_called_once_with("/created", worktree=True)

    def test_opening_worktrees_and_directories_keeps_their_markers_distinct(self):
        token = base64.urlsafe_b64encode(json.dumps({"path": "/tmp/task"}).encode()).decode()
        with patch.object(rex_worktrees, "open_session") as open_session:
            rex_worktrees.connect(token)
            open_session.assert_called_once_with("/tmp/task", worktree=True)
            open_session.reset_mock()
            rex_worktrees.connect("/tmp/task")
            open_session.assert_called_once_with("/tmp/task")

    def test_cancelled_creation_does_not_open_a_session(self):
        with (
            patch.object(rex_worktrees.worktrees, "current_parent", return_value="/workspace"),
            patch.object(rex_worktrees.worktrees, "create_worktree", return_value=None),
            patch.object(rex_worktrees, "open_session") as open_session,
        ):
            rex_worktrees.native_operation("create", "none", "")
        open_session.assert_not_called()

    def test_failure_displays_native_error_and_preserves_failure(self):
        failures = [
            (ValueError("Invalid name"), "Invalid name"),
            (OSError("Missing helper"), "Missing helper"),
            (ValueError(), "ValueError"),
            (subprocess.CalledProcessError(1, ["git"], stderr=b"  Branch exists\n"), "Branch exists"),
            (subprocess.CalledProcessError(1, ["git"]), str(subprocess.CalledProcessError(1, ["git"]))),
        ]
        for failure, message in failures:
            with (
                self.subTest(message=message),
                patch.object(rex_worktrees, "create", side_effect=failure),
                patch.object(rex_worktrees.subprocess, "run") as run,
                self.assertRaises(type(failure)),
            ):
                rex_worktrees.native_operation("create", "none", "feature-work")
            run.assert_called_once_with(
                ["rex", "do", "workspace_operation_failed", "operation=create", "message=" + message],
                check=True, stdout=subprocess.DEVNULL,
            )

    def test_background_failure_keeps_command_diagnostics_in_the_native_message(self):
        def fail(*args):
            print("Brazil: disk full", file=sys.stderr)
            raise ValueError("Worktree failed")

        with (
            patch.object(rex_worktrees, "create", side_effect=fail),
            patch.object(rex_worktrees.subprocess, "run") as run,
            self.assertRaisesRegex(ValueError, "Worktree failed"),
        ):
            rex_worktrees.native_operation("create", "none", "feature-work")
        self.assertEqual(run.call_args.args[0][-1], "message=Worktree failed\nBrazil: disk full\n")


class RexNativeDeletionTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.parent, self.target = self.root / "parent", self.root / "task"
        self.parent.mkdir()
        self.target.mkdir()
        self.token = base64.urlsafe_b64encode(json.dumps({
            "parent": str(self.parent), "path": str(self.target),
        }).encode()).decode()
        self.reply, self.prompts, self.session_list = "ok", [], []
        self.enterContext(patch.dict(os.environ, {"HERDR_ENV": "0"}))
        self.enterContext(patch.object(rex_worktrees.worktrees, "brazil_workspace", return_value=None))
        self.status = self.enterContext(patch.object(
            rex_worktrees.worktrees.subprocess, "check_output", return_value=b" M changed.txt\n",
        ))
        self.run = self.enterContext(patch.object(rex_worktrees.subprocess, "run"))
        self.enterContext(patch.object(rex_worktrees, "rex_json", side_effect=self.rex_json))
        self.enterContext(patch.object(
            rex_worktrees.worktrees, "prompt", side_effect=AssertionError("No terminal confirmation"),
        ))

    def rex_json(self, *args):
        if args == ("ls",):
            return {"sessions": self.session_list}
        self.assertEqual(args[:2], ("do", "workspace_deletion_confirm"))
        self.prompts.append(args[2])
        return self.reply

    def test_delete_native_shows_existing_scope_and_dirty_warnings_before_deleting(self):
        with patch.object(rex_worktrees.sys, "argv", [str(SOURCE), "delete-native", self.token]):
            rex_worktrees.main()
        self.assertEqual(len(self.prompts), 1)
        self.assertTrue(self.prompts[0].startswith("message=Delete " + str(self.target) + "\n"))
        self.assertIn("its Git branch and external artifacts are retained", self.prompts[0])
        self.assertIn("Uncommitted changes will be discarded", self.prompts[0])
        self.assertEqual(self.run.call_args.args[0], [
            "git", "-C", str(self.parent), "worktree", "remove", str(self.target), "--force",
        ])

    def test_clean_worktree_deletion_does_not_force_removal(self):
        self.status.return_value = b""
        rex_worktrees.native_operation("delete", self.token)
        self.assertEqual(self.run.call_args.args[0], [
            "git", "-C", str(self.parent), "worktree", "remove", str(self.target),
        ])

    def test_only_explicit_ok_from_native_confirmation_deletes(self):
        for reply in ("cancel", None, True, "yes"):
            with self.subTest(reply=reply):
                self.reply = reply
                rex_worktrees.native_operation("delete", self.token)
                self.run.assert_not_called()

    def test_primary_checkout_is_rejected_before_native_confirmation(self):
        token = base64.urlsafe_b64encode(json.dumps({
            "parent": str(self.parent), "path": str(self.parent),
        }).encode()).decode()
        with self.assertRaisesRegex(ValueError, "primary checkout"):
            rex_worktrees.native_operation("delete", token)
        self.assertEqual(self.prompts, [])
        self.assertEqual(self.run.call_args.args[0][:4], [
            "rex", "do", "workspace_operation_failed", "operation=delete",
        ])

    def test_legacy_artifacts_are_preserved_before_confirmation(self):
        (self.target / ".ai").mkdir()
        (self.target / ".ai/note.md").write_text("keep")
        with self.assertRaisesRegex(ValueError, "Preserve and migrate"):
            rex_worktrees.native_operation("delete", self.token)
        self.assertEqual(self.prompts, [])
        self.assertEqual((self.target / ".ai/note.md").read_text(), "keep")
        self.assertEqual(self.run.call_args.args[0][0], "rex")

    def test_native_delete_rejects_non_worktree_values(self):
        for value in ("none", "session:test", str(self.target)):
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "Choose a Git worktree"):
                rex_worktrees.native_operation("delete", value)
        self.assertEqual(self.prompts, [])

    def test_deleting_a_worktree_closes_only_its_marked_session_after_removal(self):
        self.session_list = [
            {"session_id": "session:tree", "label": "🥊🌴-task"},
            {"session_id": "session:directory", "label": "🥊-task"},
        ]
        with (
            patch.object(rex_worktrees.sys, "platform", "linux"),
            patch.object(rex_worktrees.worktrees, "delete_worktree", side_effect=lambda *a, **kw: self.target.rmdir()),
            patch.object(rex_worktrees, "kill_sessions") as kill,
        ):
            rex_worktrees.delete(self.token, False)
        kill.assert_called_once_with(["session:tree"])


if __name__ == "__main__":
    unittest.main()
