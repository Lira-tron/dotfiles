-- Run from the repository root: lua tests/test_init.lua
local actions, bindings, calls, picks, inputs, selections
local hosts, choice, picked_host, name, create_error, exec_error, select_error, encoded, response
local source = arg[1] or "home/.config/rex/init.lua"

local function create(host, method, args)
  assert(method == "session.create", "creation must not enumerate sessions or activity")
  calls[#calls + 1] = { host = host, args = args }
  if create_error then return nil, create_error end
  return { session_id = "session:new-" .. host }
end

local function setup()
  actions, bindings, calls, picks, inputs, selections = {}, {}, {}, {}, {}, {}
  hosts, picked_host, name = { "lyhost", "devbox" }, "devbox", "review"
  choice = "remote"
  create_error, exec_error, select_error = nil, nil, nil
  rex = {
    action = function(value) actions[value.name] = value end,
    bind = function(key, value) bindings[key] = value end,
    mode = function() end,
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
        if #picks == 1 then return choice end
        return picked_host
      end,
      input = function(opts) inputs[#inputs + 1] = opts; return name end,
    },
    layout = { block = function(opts) return { block = opts } end },
    client = { queue = function() error("Selection must be sent through its owning host") end },
  }
  -- Worktree actions have their own unit suite.
  local workspaces = package.loaded.workspaces
  package.loaded.workspaces = true
  dofile(source)
  package.loaded.workspaces = workspaces
end

local function run()
  return actions.create_session.run({ server = "lyhost", session_id = "session:lyhost", block_id = "block:remote" })
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

test("Shift+Cmd+N opens only session creation while native shortcuts stay intact", function()
  assert(actions.session_picker_native == nil and bindings["shift+cmd+n"] == "create_session")
  assert(bindings["shift+cmd+f"] == nil)
  assert(actions.new_local_session == nil and actions.new_remote_session == nil)
  assert(actions.create_session.title == "Create Session…")
  assert(bindings["shift+cmd+s"] == "session.switch")
  assert(bindings["shift+cmd+a"] == "client.sidebar.activity.toggle")
  assert(bindings["ctrl+a>shift+s"] == "session.new")
  assert(bindings["ctrl+a>f"] == "session.switch")
  assert(bindings["ctrl+a>g"] == "session.switch")
  assert(bindings["ctrl+a>w"] == "session.switch")
end)

test("the initial picker offers only local and remote creation", function()
  choice = nil
  run()
  assert(#picks == 1 and #picks[1].items == 2)
  assert(picks[1].items[1].id == "local" and picks[1].items[1].title == "New session…")
  assert(picks[1].items[2].id == "remote" and picks[1].items[2].title == "New remote session…")
  assert(#calls == 0 and #inputs == 0 and #selections == 0)
end)

test("local creation stays on the Mac while a remote pane is selected", function()
  choice, name, hosts = "local", "  review  ", {}
  run()
  assert(#picks == 1 and #inputs == 1)
  assert(#calls == 1 and calls[1].host == "local" and calls[1].args.label == "review")
  assert(#selections == 1 and selections[1].host == "local")
end)

test("chooses a host and applies its prefix exactly once", function()
  for _, label in ipairs({ "review", "🥊-review", "  review  " }) do
    setup()
    name = label
    run()
    assert(#picks == 2 and picks[2].items[1].id == "lyhost" and picks[2].items[2].id == "devbox")
    assert(inputs[1].title == "New session on devbox")
    assert(#calls == 1 and calls[1].host == "devbox" and calls[1].args.label == "🥊-review")
    assert(calls[1].args.initial_windows[1].layout.block.flavor == "com.superlogical.terminal.shell")
    assert(#selections == 1 and selections[1].host == "devbox")
  end
end)

test("cancelling the host prompt creates nothing", function()
  picked_host = nil
  run()
  assert(#calls == 0 and #inputs == 0 and #selections == 0)
end)

test("cancelled and blank names create nothing", function()
  for _, target in ipairs({ "local", "remote" }) do
    for _, value in ipairs({ false, "", " \t " }) do
      setup()
      choice, name = target, value or nil
      run()
      assert(#calls == 0 and #selections == 0)
    end
  end
end)

test("names with shell metacharacters stay data", function()
  name = 'review $(touch /tmp/unwanted) `echo no` "quoted"'
  run()
  assert(calls[1].args.label == "🥊-" .. name)
end)

test("no remote hosts does not silently create locally", function()
  hosts = {}
  local ok, err = pcall(run)
  assert(not ok and err:find("No connected remote hosts", 1, true))
  assert(#calls == 0 and #inputs == 0 and #picks == 1)
end)

test("creation errors prevent selection", function()
  for _, target in ipairs({ "local", "remote" }) do
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
