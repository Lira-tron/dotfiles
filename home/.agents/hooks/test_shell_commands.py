import unittest

from shell_commands import inert_data_command


class LiteralDataTest(unittest.TestCase):
    def test_literal_document_writes_are_allowed(self):
        self.assertTrue(inert_data_command("python3 - <<'PY'\nfrom pathlib import Path\nPath('p').write_text('Never git push')\nPY\n"))
        self.assertTrue(inert_data_command("cat <<'EOF'\ngit push\nEOF\n"))

    def test_executable_and_malformed_documents_are_not_exempt(self):
        for source in [
            "cat <<EOF\n$(git push)\nEOF\n", "cat <<'EOF'\ngit push",
            "cat /dev/null; sh <<'EOF'\ngit push\nEOF\n",
            "sh <<'EOF'\ngit push\nEOF\n",
            "cat <<'EOF'\nsafe\nEOF\ngit push\nEOF\n",
            "python3 -c 'git push' <<'PY'\nfrom pathlib import Path\nPath('p').write_text('safe')\nPY\n",
            "python3 - <<'PY'\nfrom pathlib import Path\nPath('p').write_text(eval('git push'))\nPY\n",
            "python3 - <<'PY'\nfrom pathlib import Path\nPath=eval\nPath('git push')\nPY\n",
        ]:
            with self.subTest(source=source):
                self.assertFalse(inert_data_command(source))

    def test_execution_options_and_substitutions_are_not_exempt(self):
        for source in [
            "rg --pre 'git push' file", "claude --settings 'git push'",
            "echo $(git push)", "echo `git push`", "echo safe; git push",
        ]:
            with self.subTest(source=source):
                self.assertFalse(inert_data_command(source))


if __name__ == "__main__":
    unittest.main()
