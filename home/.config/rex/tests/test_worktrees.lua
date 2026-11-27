local T = dofile("tests/rex_test.lua")
local fs, trees, artifacts = T.fs, require("worktrees"), require("artifacts")

local function fixture()
  local root = T.temp()
  local parent, target = root .. "/parent", root .. "/task"
  local source = fs.parent(fs.resolve("./worktrees.lua"))
  local repository = fs.trim(fs.run({ "git", "-C", source, "rev-parse", "--show-toplevel" }))
  fs.run({ "git", "clone", "--shared", "--no-checkout", repository, parent })
  fs.run({ "git", "-C", parent, "worktree", "add", "--detach", target, "HEAD" })
  return root, { parent = parent, path = target }
end

T.test("tokens round trip paths with quotes, tabs, newlines and Unicode", function()
  local value = { parent = "/a 'parent", path = "/🌴\tline\n$(touch BAD)" }
  local token = trees.token(value)
  assert(token:match("^tree:[0-9a-f]+$"))
  local selected = trees.decode(token)
  assert(selected.parent == value.parent and selected.path == value.path)
  for _, invalid in ipairs({ "none", "tree:1", "tree:gg", "tree:7b7d" }) do
    T.raises("Invalid worktree selection", function() trees.decode(invalid) end)
  end
end)

T.test("ordinary deletion refuses dirty files before confirmation or removal", function()
  local _, selected = fixture()
  T.write(selected.path .. "/dirty.txt", "keep")
  T.raises("Force delete", function()
    trees.delete(selected, false, function() error("unexpected confirmation") end)
  end)
  assert(fs.read(selected.path .. "/dirty.txt") == "keep")
end)

T.test("ordinary Brazil deletion never passes force", function()
  local root = T.temp()
  local owner, workspace = root .. "/owner", root .. "/owner/worktrees/task"
  local parent, target = owner .. "/src/Service", workspace .. "/src/Service"
  T.write(parent .. "/.git")
  T.write(target .. "/.git")
  T.patch(trees, "brazil_workspace", function(path) return path == parent and owner or workspace end)
  local run, removed = fs.run, false
  T.patch(fs, "run", function(argv, cwd)
    if argv[1] == "git" then return "" end
    if argv[1] == "brazil" then
      assert(table.concat(argv, "|") == "brazil|worktree|delete|--workspace|" .. owner .. "|--name|task")
      removed = true
      return ""
    end
    return run(argv, cwd)
  end)
  assert(trees.delete({ parent = parent, path = target }, false, function() return true end))
  assert(removed)
end)

T.test("Git discovery, cancellation and removal preserve parent and external artifacts", function()
  local root, selected = fixture()
  local getenv = os.getenv
  T.patch(os, "getenv", function(name) return name == "HERDR_ENV" and "1" or getenv(name) end)
  local rows = trees.current(selected.parent)
  assert(#rows == 1)
  local found = trees.decode(rows[1]:match("\t(.+)$"))
  assert(found.parent == selected.parent and found.path == selected.path)
  T.write(root .. "/external/notes.md", "keep")
  fs.run({ "ln", "-s", root .. "/external", selected.path .. "/.ai" })
  T.write(selected.path .. "/dirty.txt", "dirty")
  local function confirm(message)
    assert(message:find("Uncommitted changes will be discarded", 1, true))
    assert(message:find("its Git branch and external artifacts are retained", 1, true))
    return false
  end
  assert(not trees.delete(selected, true, confirm))
  assert(fs.read(selected.path .. "/dirty.txt") == "dirty")
  assert(trees.delete(selected, true, function(message) confirm(message); return true end))
  assert(not fs.test("-e", selected.path) and #trees.checkouts(selected.parent) == 1)
  assert(fs.read(root .. "/external/notes.md") == "keep")
end)

T.test("primary checkout and unmigrated artifacts block before confirmation", function()
  local root, selected = fixture()
  local function no_confirmation() error("unexpected confirmation") end
  T.raises("primary checkout", function()
    trees.delete({ parent = selected.parent, path = selected.parent }, true, no_confirmation)
  end)
  T.write(selected.path .. "/.ai/notes.md", "keep")
  T.raises("Preserve and migrate", function() trees.delete(selected, true, no_confirmation) end)
  assert(fs.read(selected.path .. "/.ai/notes.md") == "keep")
end)

T.test("failed removal propagates and does not report success", function()
  local _, selected = fixture()
  fs.run({ "git", "-C", selected.parent, "worktree", "lock", selected.path })
  T.raises("locked", function() trees.delete(selected, false, function() return true end) end)
  assert(fs.test("-d", selected.path))
end)

T.test("Brazil discovery deduplicates sibling packages and stays within its workspace", function()
  local root = T.temp()
  local owner, full, partial = root .. "/Service", root .. "/Service/worktrees/full", root .. "/Service/worktrees/partial"
  for _, workspace in ipairs({ owner, full, partial }) do T.write(workspace .. "/packageInfo") end
  for _, path in ipairs({ owner .. "/src/Service", owner .. "/src/CDK", full .. "/src/Service",
    full .. "/src/CDK", partial .. "/src/CDK" }) do T.write(path .. "/.git") end
  T.patch(trees, "checkouts", function(repo)
    local records = {}
    for _, workspace in ipairs({ owner, full, partial }) do
      local path = workspace .. "/src/" .. fs.name(repo)
      if fs.test("-e", path .. "/.git") then records[#records + 1] = { worktree = path } end
    end
    return records
  end)
  for _, cwd in ipairs({ owner, owner .. "/src", full, full .. "/src/Service", partial .. "/src/CDK" }) do
    local rows = trees.current(cwd)
    assert(#rows == 2, cwd)
  end
  T.write(root .. "/Empty/packageInfo")
  assert(#trees.current(root .. "/Empty") == 0)
end)

T.test("Brazil creation uses committed parents, initializes every package and forwards the name", function()
  local root = T.temp()
  local owner, parent = root .. "/Service", root .. "/Service/src/Service"
  T.write(parent .. "/.git")
  T.write(owner .. "/src/CDK/.git")
  T.write(owner .. "/packageInfo")
  local run, commands, initialized = fs.run, {}, {}
  T.patch(fs, "run", function(argv, cwd)
    if argv[1] == "brazil-context" then return argv[2] == "package" and parent or owner end
    if argv[1] == "git" then return argv[4] == "rev-parse" and "1234567890abcdef" or "main" end
    if argv[1] == "brazil" then
      commands[#commands + 1] = table.concat(argv, "|")
      for _, package in ipairs({ "Service", "CDK" }) do T.write(owner .. "/worktrees/feature-work/src/" .. package .. "/.git") end
      return ""
    end
    return run(argv, cwd)
  end)
  local result = fs.result
  T.patch(fs, "result", function(argv, cwd)
    if argv[1] == "git" then return { ok = false, code = 1, stdout = "", stderr = "" } end
    return result(argv, cwd)
  end)
  T.patch(artifacts, "initialize", function(package, feature, created)
    assert(feature == "feature-work" and created == os.date("!%y-%m-%d"))
    initialized[#initialized + 1] = fs.name(package)
  end)
  T.patch(fs, "prompt", function() error("Native creation must not read a terminal") end)
  local created = trees.create({ parent = parent }, "feature-work")
  assert(created.path == owner .. "/worktrees/feature-work/src/Service")
  assert(commands[1] == "brazil|worktree|create|--workspace|" .. owner .. "|--name|feature-work|--inheritAll")
  assert(table.concat(initialized, ",") == "CDK,Service")
  assert(trees.create({ parent = parent }, "") == nil and #commands == 1)
  T.raises("without slashes", function() trees.create({ parent = parent }, "../escape") end)
  T.patch(fs, "result", function(argv, cwd)
    if argv[1] == "git" then return { ok = true, code = 0, stdout = "", stderr = "" } end
    return result(argv, cwd)
  end)
  T.raises("already exists", function() trees.create({ parent = parent }, "feature-work") end)
  assert(#commands == 1)
end)

T.test("Brazil deletion refuses ambiguous and nested checkouts and reports all package changes", function()
  local root = T.temp()
  local owner, workspace = root .. "/owner", root .. "/owner/worktrees/task"
  local parent, target = owner .. "/src/First", workspace .. "/src/First"
  T.write(parent .. "/.git")
  T.write(target .. "/.git")
  T.write(workspace .. "/src/Second/.git")
  local selected = { parent = parent, path = target }
  local state = { ambiguous = true, removed = false }
  T.patch(trees, "brazil_workspace", function(path)
    if path == parent then return owner end
    return not state.ambiguous and workspace or nil
  end)
  T.raises("Cannot resolve", function() trees.delete(selected, true, function() error("unexpected confirmation") end) end)
  state.ambiguous = false
  T.write(target .. "/nested/.git")
  T.raises("nested Git checkouts", function() trees.delete(selected, true, function() error("unexpected confirmation") end) end)
  fs.run({ "rm", "-rf", target .. "/nested" })
  local run = fs.run
  T.patch(fs, "run", function(argv, cwd)
    if argv[1] == "git" then return argv[3]:match("/Second$") and " M changed" or "" end
    if argv[1] == "brazil" then
      assert(table.concat(argv, "|") == "brazil|worktree|delete|--workspace|" .. owner .. "|--name|task|--force")
      state.removed = true
      return ""
    end
    return run(argv, cwd)
  end)
  assert(trees.delete(selected, true, function(message)
    assert(message:find("including unmerged branches", 1, true) and message:find(workspace .. "/src/Second", 1, true))
    return true
  end))
  assert(state.removed)
end)
