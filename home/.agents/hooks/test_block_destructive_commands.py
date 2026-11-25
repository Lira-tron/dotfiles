import unittest

from block_destructive_commands import check_command


class DestructiveCommandTest(unittest.TestCase):
    def test_data_is_not_executed(self):
        for command in [
            "rg -n 'git push' config",
            'claude "Never git push or sudo anything"',
            "cat <<'EOF'\ngit push\nsudo command\nEOF\n",
            "python3 - <<'PY'\nfrom pathlib import Path\nPath('prompt').write_text('Never git push')\nPY\n",
            "git status",
            "git pull --no-rebase --ff-only",
            "cr --amend --guided --no-auto-publish",
            "rm 'git push'",
            "rg -n 'rm -rf /' config",
            "printf '%s' 'rm -rf /'",
            "coverage run --include='*/hooks/a.py,*/hooks/b.py' -m unittest",
        ]:
            with self.subTest(command=command):
                self.assertFalse(check_command(command)[0])

    def test_forbidden_commands_remain_blocked(self):
        for command in [
            "git push", "/usr/bin/git push origin main", "git -C repo push",
            "git -c advice.foo=false push", "env X=1 git push", "true && git push",
            "bash -lc 'git push'", "eval 'git push'", 'echo "$(git push)"',
            "echo `git push`", "cat <<EOF\n$(git push)\nEOF\n",
            "sh <<'EOF'\ngit push\nEOF\n",
            "python3 -c \"import os; os.system('git push')\"",
            "python3 - <<'PY'\nimport subprocess\nsubprocess.run(['git', 'push'])\nPY\n",
            "python3 - <<'PY'\nimport os\ncmd='git push'\nos.system(cmd)\nPY\n",
            "rm -rf /", "rm -rf -- /", "rm --force --recursive /",
            "rm -r -f ~/", "rm -Rf /src", "sudo command",
            "cr --auto-publish", "cr --publish", "git reset --hard", "git clean -fd",
            "2>/dev/null git push",
            "if false; then true; elif git push; then true; fi",
            "timeout 30 git push", 'env -S "git push"',
            "cat /dev/null; sh <<'EOF'\ngit push\nEOF\n",
            "python3 -c \"import subprocess; subprocess.run(['sh','-c','git push'])\"",
            "python3 -c \"import os; os.execv('/usr/bin/git', ['git', 'push'])\"",
            "python3 - <<'PY'\nPath=eval\nPath(\"__import__('os').system('git push')\")\nPY\n",
        ]:
            with self.subTest(command=command):
                self.assertTrue(check_command(command)[0])

    def test_malformed_shell_is_blocked(self):
        self.assertTrue(check_command("echo 'unterminated")[0])


if __name__ == "__main__":
    unittest.main()
