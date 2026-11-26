local T = dofile("tests/rex_test.lua")
local fs, artifacts = T.fs, require("artifacts")

local function setup()
  local root = T.temp()
  local getenv = os.getenv
  T.patch(os, "getenv", function(name) return name == "HOME" and root or getenv(name) end)
  local checkout = root .. "/source"
  T.write(checkout .. "/Config", "package.Example-Package = {\n};\n")
  return root, checkout
end

T.test("names reject paths and invalid features and strip only today's suffix", function()
  for _, name in ipairs({ "../escape", "path\\escape", "-option", "UPPER", "space name", "end-", "a--b", "" }) do
    local ok = pcall(artifacts.feature, name, "26-11-26")
    assert(not ok, name)
  end
  assert(artifacts.feature("feature-work-1126", "26-11-26") == "feature-work")
  assert(artifacts.feature("feature-work-1125", "26-11-26") == "feature-work-1125")
end)

T.test("initialization uses Config ownership and keeps the existing selection", function()
  local root, checkout = setup()
  local expected = root .. "/knowledge/ai/artifacts/Example-Package/26-11-26-feature-work"
  assert(artifacts.initialize(checkout, "feature-work", "26-11-26") == expected)
  assert(fs.test("-L", checkout .. "/.ai") and fs.resolve(checkout .. "/.ai") == expected)
  T.write(expected .. "/notes.md", "keep")
  assert(artifacts.initialize(checkout, "feature-work", "26-11-26") == expected)
  T.raises("existing artifact selection", function() artifacts.initialize(checkout, "other", "26-11-26") end)
  T.raises("existing artifact selection", function() artifacts.initialize(checkout, "feature-work", "26-11-27") end)
  assert(fs.read(expected .. "/notes.md") == "keep")
  assert(fs.run({ "find", expected, "-maxdepth", "0", "-perm", "0700" }):find(expected, 1, true))
end)

T.test("initialization refuses physical, broken and redirected artifact storage", function()
  local root, checkout = setup()
  T.write(checkout .. "/.ai/notes.md", "keep")
  T.raises("Preserve and migrate", function() artifacts.initialize(checkout, "feature-work", "26-11-26") end)
  fs.run({ "mv", checkout .. "/.ai", root .. "/saved" })
  fs.run({ "ln", "-s", root .. "/missing", checkout .. "/.ai" })
  T.raises("existing artifact selection", function() artifacts.initialize(checkout, "feature-work", "26-11-26") end)
  fs.run({ "unlink", checkout .. "/.ai" })
  fs.run({ "mkdir", "-p", root .. "/knowledge/ai/artifacts" })
  fs.run({ "ln", "-s", root .. "/saved", root .. "/knowledge/ai/artifacts/Example-Package" })
  T.raises("redirect through symlinks", function() artifacts.initialize(checkout, "feature-work", "26-11-26") end)
  assert(fs.read(root .. "/saved/notes.md") == "keep")
end)

T.test("deletion keeps external links but refuses internal and unmigrated storage", function()
  local root, checkout = setup()
  T.write(checkout .. "/.ai/note.md", "keep")
  T.raises("Preserve and migrate", function() artifacts.check_deletion(checkout, checkout) end)
  fs.run({ "mv", checkout .. "/.ai", root .. "/external" })
  fs.run({ "ln", "-s", root .. "/external", checkout .. "/.ai" })
  artifacts.check_deletion(checkout, checkout)
  fs.run({ "unlink", checkout .. "/.ai" })
  fs.run({ "ln", "-s", checkout .. "/data", checkout .. "/.ai" })
  T.raises("outside the worktree", function() artifacts.check_deletion(checkout, checkout) end)
  assert(fs.read(root .. "/external/note.md") == "keep")
end)
