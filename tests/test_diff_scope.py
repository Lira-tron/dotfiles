import json
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "home/.config/nvim"
SNACKS = Path.home() / ".local/share/nvim/lazy/snacks.nvim"


class DiffScopeTests(unittest.TestCase):
    def setUp(self):
        self.temp = self.enterContext(tempfile.TemporaryDirectory())
        self.root = Path(self.temp) / "repo"
        self.root.mkdir()
        self.git("init", "-q")
        self.git("config", "user.name", "Diff Test")
        self.git("config", "user.email", "diff@example.invalid")
        files = {"tracked.txt": "base\n", ".gitignore": "ignored*\n"}
        self.base = self.commit_tree(files)
        self.git("update-ref", "HEAD", self.base)
        self.git("read-tree", self.base)
        self.git("checkout-index", "-a")
        self.git("update-ref", "refs/remotes/origin/main", self.base)
        self.git("config", "branch." + self.git("branch", "--show-current").strip()
                 + ".remote", "origin")
        self.git("config", "branch." + self.git("branch", "--show-current").strip()
                 + ".merge", "refs/heads/main")
        self.git("config", "remote.origin.fetch",
                 "+refs/heads/*:refs/remotes/origin/*")

    def git(self, *args, input=None):
        return subprocess.check_output(
            ["git", "-C", str(self.root), *args], input=input, text=True
        )

    def commit_tree(self, files, parent=None):
        entries = []
        for name, content in sorted(files.items()):
            blob = self.git("hash-object", "-w", "--stdin", input=content).strip()
            entries.append(f"100644 blob {blob}\t{name}\n")
        tree = self.git("mktree", input="".join(entries)).strip()
        args = ["commit-tree", tree]
        if parent:
            args += ["-p", parent]
        return self.git(*args, input="fixture\n").strip()

    def picker(self, buffers=None, scope=None, group=True):
        script = Path(self.temp) / "picker.lua"
        output = Path(self.temp) / "result.json"
        before_index = self.git("ls-files", "--stage", "-z")
        disk_before = {
            str(p): p.read_bytes() for p in self.root.rglob("*")
            if p.is_file() and ".git" not in p.relative_to(self.root).parts
        }
        config = json.dumps({
            "source": str(SOURCE), "snacks": str(SNACKS), "root": str(self.root),
            "output": str(output), "buffers": buffers or {}, "scope": scope,
            "group": group,
        })
        script.write_text("""
local config = vim.json.decode([==[%s]==])
vim.opt.rtp:prepend(config.source)
vim.opt.rtp:append(config.snacks)
local Diff = require("snacks.picker.source.diff")
local captured
_G.Snacks = {
  picker = function(opts) captured = opts end,
  notify = { error = function(message) error(message) end },
}
vim.cmd.cd(config.root)
vim.cmd.edit("tracked.txt")
for path, text in pairs(config.buffers) do
  local buf = vim.fn.bufadd(config.root .. "/" .. path)
  vim.fn.bufload(buf)
  local lines = vim.split(text, "\\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].endofline = text:sub(-1) == "\\n"
end
local scope = require("config.diff-scope")
if config.scope ~= vim.NIL then
  scope.pick()
  assert(vim.wait(5000, function() return captured ~= nil end), "scope timeout")
  local choice = captured.items[config.scope]
  local picker = {
    current = function() return choice end,
    update_titles = function() end, close = function() end,
    list = { update = function() end },
  }
  captured.actions.scope_select(picker)
  captured.confirm(picker)
  captured = nil
end
scope.git_diff(config.group)
assert(vim.wait(5000, function() return captured ~= nil end), "diff timeout")
local patch = captured.diff
if captured.cmd then
  local command = { captured.cmd }
  vim.list_extend(command, captured.args)
  local result = vim.system(command, { cwd = captured.cwd, text = true }):wait()
  assert(result.code == 0, result.stderr)
  patch = result.stdout
end
local items = {}
Diff.diff({ diff = patch, group = captured.group, cwd = captured.cwd }, {})(
  function(item) items[#items + 1] = item end
)
vim.fn.writefile({ vim.json.encode(items) }, config.output)
""" % config)
        result = subprocess.run(
            ["nvim", "--clean", "--headless", "-l", str(script)],
            text=True, capture_output=True, timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before_index)
        self.assertEqual({
            str(p): p.read_bytes() for p in self.root.rglob("*")
            if p.is_file() and ".git" not in p.relative_to(self.root).parts
        }, disk_before)
        return json.loads(output.read_text())

    def test_default_includes_untracked_files_and_unsaved_buffer_contents(self):
        (self.root / "tracked.txt").write_text("disk\n")
        (self.root / "new file.txt").write_text("new on disk\n")
        items = self.picker({"tracked.txt": "buffer\n", "new file.txt": "new buffer\n"})
        by_file = {item["file"]: item["diff"] for item in items}
        self.assertEqual(set(by_file), {"tracked.txt", "new file.txt"})
        self.assertIn("+buffer", by_file["tracked.txt"])
        self.assertNotIn("+disk", by_file["tracked.txt"])
        self.assertIn("+new buffer", by_file["new file.txt"])

    def test_unsaved_reversion_removes_stale_disk_diff(self):
        (self.root / "tracked.txt").write_text("disk\n")
        self.assertEqual(self.picker({"tracked.txt": "base\n"}), [])

    def test_unsaved_new_file_is_included_without_writing_it(self):
        items = self.picker({"unsaved.txt": "only in the editor\n"})
        self.assertEqual([item["file"] for item in items], ["unsaved.txt"])
        self.assertIn("+only in the editor", items[0]["diff"])

    def test_unstaged_scope_uses_index_including_new_files(self):
        blob = self.git("hash-object", "-w", "--stdin", input="staged\n").strip()
        self.git("update-index", "--cacheinfo", f"100644,{blob},tracked.txt")
        (self.root / "tracked.txt").write_text("staged\n")
        (self.root / "new.txt").write_text("new\n")
        items = self.picker({"tracked.txt": "buffer\n"}, scope=3)
        by_file = {item["file"]: item["diff"] for item in items}
        self.assertEqual(set(by_file), {"tracked.txt", "new.txt"})
        self.assertIn("-staged", by_file["tracked.txt"])
        self.assertNotIn("-base", by_file["tracked.txt"])

    def test_ignored_files_and_nested_repositories_are_excluded(self):
        (self.root / "ignored.txt").write_text("ignored\n")
        nested = self.root / "nested"
        nested.mkdir()
        subprocess.run(["git", "init", "-q", str(nested)], check=True)
        (nested / "file.txt").write_text("nested\n")
        items = self.picker({
            "ignored.txt": "unsaved ignored\n", "ignored-new.txt": "ignored\n",
            "nested/file.txt": "unsaved nested\n",
        })
        self.assertEqual(items, [])

    def test_empty_and_binary_untracked_files_are_listed(self):
        (self.root / "empty.txt").touch()
        (self.root / "binary.dat").write_bytes(b"\0binary")
        items = self.picker()
        self.assertEqual({item["file"] for item in items}, {"empty.txt", "binary.dat"})

    def test_hunks_have_current_buffer_line_positions(self):
        text = "base\n" + "".join(f"line {i}\n" for i in range(12))
        self.base = self.commit_tree({"tracked.txt": text, ".gitignore": "ignored*\n"})
        self.git("update-ref", "HEAD", self.base)
        self.git("update-ref", "refs/remotes/origin/main", self.base)
        self.git("read-tree", self.base)
        (self.root / "tracked.txt").write_text(text)
        changed = text.replace("base\n", "first\n").replace("line 11\n", "last\n")
        items = self.picker({"tracked.txt": changed}, group=False)
        self.assertEqual(len(items), 2)
        self.assertEqual([item["pos"][0] for item in items], [1, 10])
        self.assertIn("+last", items[1]["diff"])

    def test_default_retains_committed_changes_against_upstream(self):
        commit = self.commit_tree({
            "tracked.txt": "committed\n", ".gitignore": "ignored*\n",
        }, parent=self.base)
        self.git("update-ref", "HEAD", commit)
        self.git("read-tree", commit)
        (self.root / "tracked.txt").write_text("committed\n")
        (self.root / "new.txt").write_text("new\n")
        items = self.picker({"tracked.txt": "unsaved\n"})
        by_file = {item["file"]: item["diff"] for item in items}
        self.assertEqual(set(by_file), {"tracked.txt", "new.txt"})
        self.assertIn("-base", by_file["tracked.txt"])
        self.assertIn("+unsaved", by_file["tracked.txt"])

    def test_selected_commit_uses_its_parent_as_the_base(self):
        commit = self.commit_tree({
            "tracked.txt": "committed\n", ".gitignore": "ignored*\n",
        }, parent=self.base)
        self.git("update-ref", "HEAD", commit)
        self.git("update-ref", "refs/remotes/origin/main", commit)
        self.git("read-tree", commit)
        (self.root / "tracked.txt").write_text("committed\n")
        items = self.picker({"tracked.txt": "unsaved\n"}, scope=4)
        self.assertEqual(len(items), 1)
        self.assertIn("-base", items[0]["diff"])
        self.assertIn("+unsaved", items[0]["diff"])

    def test_deleted_file_restored_in_buffer_is_not_shown_as_deleted(self):
        (self.root / "tracked.txt").unlink()
        self.assertEqual(self.picker({"tracked.txt": "base\n"}), [])

    def test_saved_deletion_and_mode_changes_remain_visible(self):
        (self.root / "tracked.txt").unlink()
        (self.root / ".gitignore").chmod(0o755)
        items = self.picker()
        by_file = {item["file"]: item for item in items}
        self.assertEqual(set(by_file), {"tracked.txt", ".gitignore"})
        self.assertEqual(by_file["tracked.txt"]["block"]["delete"], "100644")
        self.assertEqual(by_file[".gitignore"]["block"]["mode"]["to"], "100755")

    def test_staged_rename_with_unsaved_edits_keeps_original_baseline(self):
        blob = self.git("rev-parse", "HEAD:tracked.txt").strip()
        self.git("update-index", "--force-remove", "tracked.txt")
        self.git("update-index", "--add", "--cacheinfo", f"100644,{blob},renamed.txt")
        (self.root / "tracked.txt").rename(self.root / "renamed.txt")
        items = self.picker({"renamed.txt": "buffer\n"})
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["file"], "renamed.txt")
        self.assertEqual(items[0]["rename"], "tracked.txt")
        self.assertIn("-base", items[0]["diff"])
        self.assertIn("+buffer", items[0]["diff"])

    def test_file_removed_from_index_does_not_get_duplicate_new_file_diff(self):
        self.git("update-index", "--force-remove", "tracked.txt")
        self.assertEqual(self.picker(), [])

    def test_unsaved_edit_preserves_missing_final_newline(self):
        items = self.picker({"tracked.txt": "buffer"})
        self.assertEqual(len(items), 1)
        self.assertIn("+buffer\n\\ No newline at end of file", items[0]["diff"])

    def test_untracked_symlink_shows_link_target_without_reading_target_contents(self):
        target = Path(self.temp) / "outside.txt"
        target.write_text("outside contents\n")
        (self.root / "link").symlink_to(target)
        items = self.picker()
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["file"], "link")
        self.assertEqual(items[0]["block"]["new"], "120000")
        self.assertIn("+" + str(target), items[0]["diff"])
        self.assertNotIn("outside contents", items[0]["diff"])

    def test_unsaved_dos_buffer_compares_against_original_crlf_bytes(self):
        commit = self.commit_tree({
            "tracked.txt": "base\r\n", ".gitignore": "ignored*\n",
        })
        self.git("update-ref", "HEAD", commit)
        self.git("update-ref", "refs/remotes/origin/main", commit)
        self.git("read-tree", commit)
        (self.root / "tracked.txt").write_bytes(b"disk\r\n")
        self.assertEqual(self.picker({"tracked.txt": "base\n"}), [])

    def test_unstaged_scope_preserves_git_merge_conflict_diff(self):
        blob = self.git("rev-parse", "HEAD:tracked.txt").strip()
        self.git("update-index", "--index-info", input=(
            "0 " + "0" * 40 + "\ttracked.txt\n"
            + "".join(f"100644 {blob} {stage}\ttracked.txt\n" for stage in [1, 2, 3])
        ))
        items = self.picker({"tracked.txt": "resolving\n"}, scope=3)
        self.assertEqual(len(items), 1)
        self.assertIn("diff --cc tracked.txt", items[0]["diff"])
        self.assertNotIn("+resolving", items[0]["diff"])


if __name__ == "__main__":
    unittest.main()
