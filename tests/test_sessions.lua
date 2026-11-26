-- Run from the repository root: lua tests/test_sessions.lua
local sessions, calls, picks, inputs, selections, prompt_order
local hosts, choice, name, create_error, exec_error, select_error, encoded, response
local answers, listed, deleted, list_error, delete_error
local ctx, workspace_calls, directory_rows
local source = arg[1] or "home/.config/rex/sessions.lua"

local function create(host, method, args)
  assert(method == "session.create", "creation must not enumerate sessions or activity")
  calls[#calls + 1] = { host = host, args = args }
  if create_error then return nil, create_error end
  return { session_id = "session:new-" .. host }
end

local function setup()
  calls, picks, inputs, selections = {}, {}, {}, {}
  prompt_order = {}
  hosts, name = { "lyhost", "devbox" }, "review"
  choice = "remote:devbox"
  create_error, exec_error, select_error = nil, nil, nil
  answers, listed, deleted, list_error, delete_error = nil, {}, {}, nil, nil
  ctx, workspace_calls = { server = "lyhost", session_id = "session:test", block_id = "block:test" }, {}
  directory_rows = { { name = "project", path = "/tmp/my projects/project/" } }
  rex = {
    servers = function() return hosts end,
    server = function(host)
      return { call = function(method, args)
        return create(host, method, args)
      end }
    end,
    call = function() error("Used the focused pane's host instead of the chosen host") end,
    exec = function(argv)
      assert(argv[1] == "/bin/zsh" and argv[2] == "-c")
      assert(argv[3]:find("unset REX_SERVER REX_SESSION REX_BLOCK REX_CLIENT", 1, true))
      assert(argv[3]:find('exec rex "$@"', 1, true), "arguments must not be shell-interpolated")
      assert(argv[4] == "rex")
      if exec_error then return nil, exec_error end
      if argv[5] == "api" then
        assert(argv[6] == "call")
        local err
        response, err = create("local", argv[7], encoded)
        return { ok = response ~= nil, stdout = "response", stderr = err }
      end
      local host, offset = "local", 5
      if argv[offset] == "-S" then host, offset = argv[offset + 1], offset + 2 end
      if argv[offset] == "ls" then
        assert(argv[offset + 1] == "--json")
        listed[#listed + 1] = host
        if list_error == host then return { ok = false, stderr = "Host unavailable" } end
        response = { sessions = { { session_id = "session:shared", label = "work" } } }
        return { ok = true, stdout = "response" }
      end
      if argv[offset] == "session" then
        assert(argv[offset + 1] == "kill" and #argv == offset + 2)
        deleted[#deleted + 1] = { host = host, id = argv[offset + 2] }
        if delete_error then return { ok = false, stderr = delete_error } end
        return { ok = true, stdout = "" }
      end
      assert(argv[offset] == "do" and argv[offset + 1] == "session.select")
      if select_error then return { ok = false, stderr = select_error } end
      local id = argv[offset + 2]:match("^session_id=(.+)$")
      if id ~= "session:new-" .. host then
        return { ok = false, stderr = "Session was not found on this server" }
      end
      selections[#selections + 1] = { host = host, session_id = id }
      return { ok = true, stdout = "" }
    end,
    json = {
      encode = function(value) encoded = value; return "request" end,
      decode = function(value) assert(value == "response"); return response end,
    },
    ui = {
      pick = function(opts)
        picks[#picks + 1] = opts
        prompt_order[#prompt_order + 1] = "pick"
        if answers then return answers[#picks] or nil end
        return choice
      end,
      input = function(opts)
        inputs[#inputs + 1] = opts
        prompt_order[#prompt_order + 1] = "input"
        return name
      end,
    },
    layout = { block = function(opts) return { block = opts } end },
    client = { queue = function() error("Selection must be sent through its owning host") end },
  }
  local previous = package.loaded.workspaces
  package.loaded.workspaces = function(context, operation, value)
    workspace_calls[#workspace_calls + 1] = { ctx = context, operation = operation, value = value }
    if operation == "directories" then return directory_rows end
    assert(operation == "connect")
  end
  sessions = dofile(source)
  package.loaded.workspaces = previous
end

local function run()
  return sessions.create(choice, name)
end

local function test(title, fn)
  setup()
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL: " .. title .. ": " .. tostring(err) .. "\n")
    os.exit(1)
  end
  print("PASS: " .. title)
end

test("session choices show local creation and each remote host directly", function()
  local items = sessions.items()
  assert(#items == 3)
  assert(items[1].id == "local" and items[1].subtitle == "This Mac")
  assert(items[2].id == "remote:lyhost" and items[2].title == "🥊 Create remote session")
  assert(items[2].subtitle == "lyhost")
  assert(items[3].id == "remote:devbox" and items[3].title == "🥊 Create remote session")
  assert(items[3].subtitle == "devbox")
end)

test("a host named local stays distinct from the local Mac", function()
  hosts = { "local" }
  local items = sessions.items()
  assert(items[1].id == "local" and items[2].id == "remote:local")
end)

test("the session picker chooses local or a host before asking for its name", function()
  for _, target in ipairs({ "local", "remote:lyhost", "remote:devbox" }) do
    setup()
    choice, name = target, "  review  "
    sessions.pick(ctx)
    local host = target == "local" and "local" or target:sub(8)
    assert(#picks == 1 and #picks[1].items == 5, "no extra host or worktree menu")
    assert(picks[1].items[1].title == "Create session" and picks[1].items[1].subtitle == "This Mac")
    assert(picks[1].items[2].subtitle == "lyhost" and picks[1].items[3].subtitle == "devbox")
    assert(table.concat(prompt_order, ",") == "pick,input")
    assert(#inputs == 1)
    assert(inputs[1].title == (target == "local" and "Session:" or host .. " session:"))
    assert(inputs[1].confirm == "Create")
    assert(#calls == 1 and calls[1].host == host)
    assert(calls[1].args.label == (target == "local" and "review" or "🥊-review"))
    assert(#selections == 1 and selections[1].host == host)
  end
end)

test("session deletion lists every host and closes only the explicitly confirmed target", function()
  for _, location in ipairs({ "local", "remote:lyhost", "remote:devbox" }) do
    setup()
    answers = { "delete", location .. "/session:shared", "delete" }
    sessions.pick(ctx)
    local host = location == "local" and "local" or location:sub(8)
    assert(picks[1].items[4].title == "Delete session…")
    assert(#picks == 3 and #inputs == 0 and #calls == 0 and #selections == 0)
    assert(table.concat(listed, ",") == "local,lyhost,devbox")
    assert(#picks[2].items == 3 and picks[2].items[1].subtitle == "This Mac")
    assert(picks[2].items[2].subtitle == "lyhost" and picks[2].items[3].subtitle == "devbox")
    assert(picks[3].title == "Delete work on " .. (host == "local" and "This Mac" or host) .. "?")
    assert(picks[3].items[1].id == "cancel" and picks[3].items[1].title == "No")
    assert(picks[3].items[2].title == "Yes")
    assert(picks[3].items[2].subtitle:find("programs will close", 1, true))
    assert(#deleted == 1 and deleted[1].host == host and deleted[1].id == "session:shared")
  end
end)

test("cancelling the session list or confirmation never deletes anything", function()
  for _, reply in ipairs({ false, "cancel", "other" }) do
    setup()
    answers = { "delete", "local/session:shared", reply }
    sessions.pick(ctx)
    assert(#deleted == 0)
  end
  setup()
  answers = { "delete" }
  sessions.pick(ctx)
  assert(#picks == 2 and #deleted == 0)
end)

test("session listing failure does not offer a partial list or delete anything", function()
  answers, list_error = { "delete" }, "devbox"
  local ok, err = pcall(sessions.pick, ctx)
  assert(not ok and err == "Host unavailable")
  assert(#picks == 1 and #deleted == 0)
end)

test("directory shortcuts are in the session menu and open on the pane's host", function()
  choice = "dir:/tmp/my projects/project/"
  sessions.pick(ctx)
  local directory = picks[1].items[5]
  assert(directory.title == "project" and directory.icon == "folder")
  assert(directory.subtitle == "lyhost · /tmp/my projects/project/")
  assert(#workspace_calls == 2)
  assert(workspace_calls[1].operation == "directories" and workspace_calls[1].ctx == ctx)
  assert(workspace_calls[2].operation == "connect" and workspace_calls[2].ctx == ctx)
  assert(workspace_calls[2].value == "/tmp/my projects/project/")
  assert(#inputs == 0 and #calls == 0)
end)

test("empty directory lists retain the session actions", function()
  directory_rows, choice = {}, nil
  sessions.pick(ctx)
  assert(#picks[1].items == 4)
end)

test("session deletion errors do not fall back to a different host", function()
  answers, delete_error = { "delete", "remote:devbox/session:shared", "delete" }, "Could not close session"
  local ok, err = pcall(sessions.pick, ctx)
  assert(not ok and err == delete_error)
  assert(#deleted == 1 and deleted[1].host == "devbox")
end)

test("cancelling session selection asks for no name and creates nothing", function()
  choice = nil
  sessions.pick(ctx)
  assert(#picks == 1 and #inputs == 0 and #calls == 0 and #selections == 0)
end)

test("cancelled or blank names create nothing on local and remote hosts", function()
  for _, target in ipairs({ "local", "remote:devbox" }) do
    for _, value in ipairs({ false, "", " \t " }) do
      setup()
      choice, name = target, value or nil
      sessions.pick(ctx)
      assert(#picks == 1 and #inputs == 1 and #calls == 0 and #selections == 0)
    end
  end
end)

test("local creation stays on the Mac while a remote pane is selected", function()
  choice, name, hosts = "local", "review", {}
  run()
  assert(#picks == 0 and #inputs == 0)
  assert(#calls == 1 and calls[1].host == "local" and calls[1].args.label == "review")
  assert(#selections == 1 and selections[1].host == "local")
end)

test("chooses a host and applies its prefix exactly once", function()
  for _, label in ipairs({ "review", "🥊-review" }) do
    setup()
    name = label
    run()
    assert(#picks == 0 and #inputs == 0)
    assert(#calls == 1 and calls[1].host == "devbox" and calls[1].args.label == "🥊-review")
    assert(calls[1].args.initial_windows[1].layout.block.flavor == "com.superlogical.terminal.shell")
    assert(#selections == 1 and selections[1].host == "devbox")
  end
end)

test("names with shell metacharacters stay data", function()
  name = 'review $(touch /tmp/unwanted) `echo no` "quoted"'
  run()
  assert(calls[1].args.label == "🥊-" .. name)
end)

test("no remote hosts offers only the local Mac", function()
  hosts = {}
  local items = sessions.items()
  assert(#items == 1 and items[1].id == "local")
end)

test("creation errors prevent selection", function()
  for _, target in ipairs({ "local", "remote:devbox" }) do
    setup()
    choice, create_error = target, "Session limit reached"
    local ok, err = pcall(run)
    assert(not ok and err == create_error and #selections == 0)
  end
end)

test("selection errors are reported without creating a second session", function()
  select_error = "Go to Session failed on devbox"
  local ok, err = pcall(run)
  assert(not ok and err == select_error and #calls == 1 and #selections == 0)
end)

test("CLI launch failures are surfaced", function()
  exec_error = "Could not launch rex"
  local ok, err = pcall(run)
  assert(not ok and err == exec_error and #calls == 1 and #selections == 0)
end)
