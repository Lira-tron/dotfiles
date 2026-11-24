import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "home/.config/television/cable/rex-worktrees.py"
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


if __name__ == "__main__":
    unittest.main()
