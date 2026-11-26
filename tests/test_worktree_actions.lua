local T = dofile("tests/rex_test.lua")
local fs, trees, actions = T.fs, require("worktrees"), require("worktree_actions")

T.test("session prefixes remain distinct and idempotent", function()
  for _, case in ipairs({
    { false, false, "review" }, { false, true, "🥊-review" },
    { true, false, "🌴-review" }, { true, true, "🥊🌴-review" },
  }) do
    assert(actions.label("review", case[1], case[2]) == case[3])
    assert(actions.label(case[3], case[1], case[2]) == case[3])
  end
end)

T.test("opening uses the owning host, worktree cwd and matching session only", function()
  local state = { sessions = {}, requests = {}, selected = {} }
  T.patch(actions, "session_name", function() return "feature" end)
  T.patch(rex, "call", function(method, args)
    if method == "session.list" then return { sessions = state.sessions } end
    assert(method == "session.create")
    state.requests[#state.requests + 1] = args
    return { session_id = "session:new" }
  end)
  T.patch(fs, "run", function(argv)
    if argv[1] == "uname" then return "Linux\n" end
    assert(table.concat(argv, "|") == "rex|do|session.select|session_id=session:new")
    state.selected[#state.selected + 1] = argv
    return ""
  end)
  actions.open("/worktree", true)
  assert(#state.requests == 1 and state.requests[1].label == "🥊🌴-feature")
  assert(state.requests[1].initial_windows[1].layout.block.options.cwd == "/worktree")
  state.sessions = { { session_id = "session:new", label = "🥊🌴-feature" } }
  actions.open("/worktree", true)
  assert(#state.requests == 1 and #state.selected == 2)
  T.patch(rex, "call", function() return nil, "Host unavailable" end)
  T.raises("Host unavailable", function() actions.open("/worktree", true) end)
  assert(#state.selected == 2)
end)

T.test("worktree and directory selections preserve their naming type", function()
  local opened = {}
  T.patch(actions, "open", function(path, worktree) opened[#opened + 1] = { path, worktree } end)
  actions.connect("/directory")
  actions.connect(trees.token({ parent = "/parent", path = "/worktree" }))
  assert(opened[1][1] == "/directory" and opened[1][2] == false)
  assert(opened[2][1] == "/worktree" and opened[2][2] == true)
end)

T.test("creation passes native name and selects only after success", function()
  local state = { requests = {}, opens = 0 }
  T.patch(trees, "current_parent", function(cwd) assert(cwd == "/cwd"); return "/parent" end)
  T.patch(trees, "create", function(selected, name)
    state.requests[#state.requests + 1] = { selected, name }
    return name ~= "" and { path = "/created" } or nil
  end)
  T.patch(actions, "open", function(path, worktree)
    assert(path == "/created" and worktree)
    state.opens = state.opens + 1
  end)
  actions.create("none", "feature", "/cwd")
  assert(state.requests[1][1].parent == "/parent" and state.requests[1][2] == "feature")
  actions.create("none", "", "/cwd")
  assert(state.opens == 1)
end)

T.test("native confirmation accepts only explicit approval and displays operation failures", function()
  local state = { reply = "ok", confirmations = {}, deleted = 0, failures = {} }
  T.patch(actions, "delete", function(value, force, confirm)
    assert(value == "tree:00" and force == false)
    if confirm("Full deletion scope\nDirty files") then state.deleted = state.deleted + 1 end
  end)
  T.patch(rex, "invoke", function(operation, args)
    if operation == "workspace_deletion_confirm" then
      state.confirmations[#state.confirmations + 1] = args.message
      return state.reply
    end
    assert(operation == "workspace_operation_failed")
    state.failures[#state.failures + 1] = args
  end)
  for _, reply in ipairs({ "ok", "cancel", true, "yes" }) do
    state.reply = reply
    actions.native("delete", "tree:00")
  end
  assert(state.deleted == 1 and #state.confirmations == 4)
  assert(state.confirmations[1] == "Full deletion scope\nDirty files")
  T.patch(actions, "create", function() error("Git creation failed", 0) end)
  T.raises("Git creation failed", function() actions.native("create", "none", "feature", "/cwd") end)
  assert(state.failures[1].operation == "create" and state.failures[1].message == "Git creation failed")
  T.raises("Choose a Git worktree", function() actions.native("delete", "session:other") end)
end)

T.test("worktree removal closes only its marked session after confirmed success", function()
  local state = { approved = false, removed = false, killed = {} }
  T.patch(actions, "session_name", function() return "task" end)
  T.patch(rex, "call", function(method)
    assert(method == "session.list")
    return { sessions = {
      { session_id = "session:tree", label = "🥊🌴-task" },
      { session_id = "session:directory", label = "🥊-task" },
    } }
  end)
  T.patch(fs, "run", function(argv)
    if argv[1] == "uname" then return "Linux\n" end
    assert(state.removed, "session closed before removal")
    state.killed[#state.killed + 1] = table.concat(argv, "|")
    return ""
  end)
  T.patch(fs, "test", function() return not state.removed end)
  T.patch(trees, "delete", function(_, _, confirm)
    state.removed = confirm("Deletion scope")
    return state.removed
  end)
  local token = trees.token({ parent = "/parent", path = "/task" })
  local function confirm(message)
    assert(message:find("Rex session 🥊🌴-task will be closed.", 1, true))
    return state.approved
  end
  actions.delete(token, false, confirm)
  assert(#state.killed == 0)
  state.approved = true
  actions.delete(token, false, confirm)
  assert(#state.killed == 1 and state.killed[1] == "rex|session|kill|session:tree")
end)

T.test("Television session creation retains the selected remote and literal name", function()
  local state = { answers = { "devbox", "review ' $(echo no)" }, commands = {} }
  T.patch(rex, "servers", function() return { "devbox", "other" } end)
  T.patch(fs, "prompt", function() return table.remove(state.answers, 1) end)
  T.patch(fs, "run", function(argv)
    state.commands[#state.commands + 1] = argv
    assert(argv[1] == "rex" and argv[2] == "-S" and argv[3] == "devbox")
    if argv[4] == "ls" then return rex.json.encode({ sessions = {} }) end
    if argv[4] == "new" then
      assert(argv[5] == "🥊-review ' $(echo no)" and argv[6] == "--json" and #argv == 6)
      return rex.json.encode({ session_id = "session:remote" })
    end
    assert(argv[4] == "do" and argv[6] == "session_id=session:remote")
    return ""
  end)
  actions.create_session("/local/path")
  assert(#state.commands == 3)
end)
