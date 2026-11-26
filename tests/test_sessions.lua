-- Run from the repository root: lua tests/test_sessions.lua
local sessions, calls, picks, inputs, selections
local hosts, choice, name, create_error, exec_error, select_error, encoded, response
local source = arg[1] or "home/.config/rex/sessions.lua"

local function create(host, method, args)
  assert(method == "session.create", "creation must not enumerate sessions or activity")
  calls[#calls + 1] = { host = host, args = args }
  if create_error then return nil, create_error end
  return { session_id = "session:new-" .. host }
end

local function setup()
  calls, picks, inputs, selections = {}, {}, {}, {}
  hosts, name = { "lyhost", "devbox" }, "review"
  choice = "remote:devbox"
  create_error, exec_error, select_error = nil, nil, nil
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
      pick = function() error("Session creation must not open another host picker") end,
      input = function() error("The name has already been entered") end,
    },
    layout = { block = function(opts) return { block = opts } end },
    client = { queue = function() error("Selection must be sent through its owning host") end },
  }
  sessions = dofile(source)
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
