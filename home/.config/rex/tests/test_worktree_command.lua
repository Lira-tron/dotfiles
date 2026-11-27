local T = dofile("tests/rex_test.lua")
local fs, actions = T.fs, require("worktree_actions")
local script = "./worktree_command.lua"

T.test("detached commands route explicit names and native confirmations without terminal prompts", function()
  local requests = {}
  T.patch(fs, "run", function(argv) assert(argv[1] == "pwd"); return "/pane/cwd\n" end)
  T.patch(fs, "prompt", function() error("Detached operation read a terminal") end)
  T.patch(actions, "native", function(operation, value, name, cwd)
    requests[#requests + 1] = { operation = operation, value = value, name = name, cwd = cwd }
  end)
  T.patch(rex, "args", { operation = "create-named", value = "none", name = "feature-work" })
  dofile(script)
  assert(requests[1].operation == "create" and requests[1].name == "feature-work")
  assert(requests[1].value == "none" and requests[1].cwd == "/pane/cwd")
  rex.args = { operation = "delete-native", value = "tree:00" }
  dofile(script)
  assert(requests[2].operation == "delete" and requests[2].value == "tree:00")
end)

T.test("Television create, connect and delete route to Rex Lua actions", function()
  local called = {}
  T.patch(fs, "run", function() return "/pane/cwd\n" end)
  for _, operation in ipairs({ "create", "connect", "create_session" }) do
    T.patch(actions, operation, function(...) called[#called + 1] = { operation, ... } end)
  end
  T.patch(actions, "delete", function(value, force, confirm)
    called[#called + 1] = { "delete", value, force }
    assert(confirm("scope") == true)
  end)
  T.patch(fs, "prompt", function() return "ok" end)
  T.patch(rex, "args", { operation = "connect", value = "none" })
  dofile(script)
  rex.args = { operation = "create", value = "session:example" }
  dofile(script)
  rex.args = { operation = "connect", value = "/directory" }
  dofile(script)
  rex.args = { operation = "delete", value = "tree:00", force = true }
  dofile(script)
  assert(called[1][1] == "create" and called[1][2] == "none")
  assert(called[2][1] == "create_session" and called[2][2] == "/pane/cwd")
  assert(called[3][1] == "connect" and called[3][2] == "/directory")
  assert(called[4][1] == "delete" and called[4][3] == true)
end)

T.test("unknown commands fail without running an operation", function()
  T.patch(rex, "args", { operation = "invalid" })
  T.raises("Unknown Rex worktree action: invalid", function() dofile(script) end)
end)
