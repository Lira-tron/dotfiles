-- Run from the repository root: lua tests/test_init.lua
local action, bindings, calls, picks, inputs, queued, warnings
local hosts, answers, name, failures, exec_error, encoded, response
local source = arg[1] or "home/.config/rex/init.lua"

local function api(host, method, args)
  calls[#calls + 1] = { host = host, method = method, args = args }
  if failures[host .. ":" .. method] then
    return nil, failures[host .. ":" .. method]
  end
  if method == "session.list" then
    return { sessions = { { session_id = "session:" .. host, label = host .. " work" } } }
  end
  assert(method == "session.create")
  return { session_id = "session:new-" .. host }
end

local function setup()
  bindings, calls, picks, inputs, queued, warnings = {}, {}, {}, {}, {}, {}
  hosts, answers, name, failures, exec_error = { "lyhost", "devbox" }, {}, "review", {}, nil
  rex = {
    action = function(value)
      if value.name == "session_picker_native" then action = value end
    end,
    bind = function(key, value) bindings[key] = value end,
    mode = function() end,
    servers = function() return hosts end,
    server = function(host)
      return { call = function(method, args) return api(host, method, args) end }
    end,
    -- The default API follows the focused remote pane and must never be used
    -- to discover or create local sessions.
    call = function() error("Used the focused pane's host instead of the chosen host") end,
    exec = function(argv)
      assert(argv[1] == "/bin/zsh" and argv[2] == "-c")
      assert(argv[3]:find("unset REX_SERVER REX_SESSION REX_BLOCK REX_CLIENT", 1, true))
      assert(argv[3]:find('exec rex "$@"', 1, true), "arguments must not be shell-interpolated")
      assert(argv[4] == "rex" and argv[5] == "api" and argv[6] == "call")
      if exec_error then return nil, exec_error end
      local err
      response, err = api("local", argv[7], encoded)
      return { ok = response ~= nil, stdout = "response", stderr = err }
    end,
    json = {
      encode = function(value) encoded = value; return "request" end,
      decode = function(value) assert(value == "response"); return response end,
    },
    ui = {
      pick = function(opts)
        picks[#picks + 1] = opts
        return answers[#picks]
      end,
      input = function(opts) inputs[#inputs + 1] = opts; return name end,
    },
    layout = { block = function(opts) return { block = opts } end },
    client = { queue = function(cmd, args) queued[#queued + 1] = { cmd = cmd, args = args } end },
    log = function(level, message) warnings[#warnings + 1] = { level, message } end,
  }
  -- Worktree actions have their own unit suite.
  local workspaces = package.loaded.workspaces
  package.loaded.workspaces = true
  dofile(source)
  package.loaded.workspaces = workspaces
end

local function run()
  return action.run({ server = "lyhost", session_id = "session:lyhost", block_id = "block:remote" })
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

local function created()
  for _, call in ipairs(calls) do
    if call.method == "session.create" then return call end
  end
end

test("the experimental shortcut preserves existing session and activity shortcuts", function()
  assert(bindings["shift+cmd+f"] == "session_picker_native")
  assert(bindings["shift+cmd+s"] == "session.switch")
  assert(bindings["shift+cmd+a"] == "client.sidebar.activity.toggle")
  assert(bindings["ctrl+a>f"] == "session.switch")
  assert(bindings["ctrl+a>g"] == "session.switch")
  assert(bindings["ctrl+a>w"] == "session.switch")
end)

test("lists creation actions and sessions with native icons and host labels", function()
  run()
  local items = picks[1].items
  assert(#items == 5)
  assert(items[1].id == "new_local" and items[2].id == "new_remote")
  assert(items[3].id == "session:local" and items[3].subtitle == "This Mac")
  assert(items[3].icon == "terminal")
  assert(items[4].id == "session:lyhost" and items[4].subtitle == "lyhost")
  assert(items[4].icon == "server" and items[5].subtitle == "devbox")
  assert(created() == nil and #queued == 0 and #inputs == 0)
end)

test("switches to existing local and remote sessions without creating one", function()
  for _, id in ipairs({ "session:local", "session:lyhost", "session:devbox" }) do
    setup()
    answers = { id }
    run()
    assert(created() == nil and #inputs == 0 and #queued == 1)
    assert(queued[1].cmd == "session.select" and queued[1].args.session_id == id)
  end
end)

test("local creation stays on the Mac while a remote pane is selected", function()
  answers, name = { "new_local" }, "  review  "
  run()
  assert(created().host == "local" and created().args.label == "review")
  assert(created().args.initial_windows[1].layout.block.flavor == "com.superlogical.terminal.shell")
  assert(queued[1].args.session_id == "session:new-local")
  assert(#picks == 1 and #inputs == 1)
end)

test("remote creation uses the chosen host and prefixes the name exactly once", function()
  for _, label in ipairs({ "review", "🥊-review" }) do
    setup()
    answers, name = { "new_remote", "devbox" }, label
    run()
    assert(picks[2].items[1].id == "lyhost" and picks[2].items[2].id == "devbox")
    assert(inputs[1].title == "New session on devbox")
    assert(created().host == "devbox" and created().args.label == "🥊-review")
    assert(queued[1].args.session_id == "session:new-devbox")
  end
end)

test("cancelling host selection performs no creation and asks for no name", function()
  answers = { "new_remote" }
  run()
  assert(created() == nil and #inputs == 0 and #queued == 0)
end)

test("cancelled and blank names create nothing on either host", function()
  for _, choice in ipairs({ "new_local", "new_remote" }) do
    for _, value in ipairs({ false, "", " \t " }) do
      setup()
      answers, name = { choice, "lyhost" }, value or nil
      run()
      assert(created() == nil and #queued == 0)
    end
  end
end)

test("session names are passed as data including shell metacharacters", function()
  answers, name = { "new_local" }, 'review $(touch /tmp/unwanted) `echo no` "quoted"'
  run()
  assert(created().args.label == name)
end)

test("no remote hosts does not silently create locally", function()
  hosts, answers = {}, { "new_remote" }
  local ok, err = pcall(run)
  assert(not ok and err:find("No connected remote hosts", 1, true))
  assert(created() == nil and #queued == 0 and #inputs == 0)
end)

test("an unavailable remote host does not hide sessions on other hosts", function()
  failures["lyhost:session.list"] = "Host disconnected"
  run()
  assert(#picks[1].items == 4 and picks[1].items[4].subtitle == "devbox")
  assert(#warnings == 1 and warnings[1][2]:find("Host disconnected", 1, true))
end)

test("creation errors are surfaced without selecting a session", function()
  for _, host in ipairs({ "local", "lyhost" }) do
    setup()
    failures[host .. ":session.create"] = "Session limit reached"
    answers = { host == "local" and "new_local" or "new_remote", host }
    local ok, err = pcall(run)
    assert(not ok and err == "Session limit reached" and #queued == 0)
  end
end)

test("local discovery failures are surfaced without showing incomplete results", function()
  failures["local:session.list"] = "Local server unavailable"
  local ok, err = pcall(run)
  assert(not ok and err == "Local server unavailable" and #picks == 0)
end)

test("failure launching the local CLI is surfaced", function()
  exec_error = "Could not launch rex"
  local ok, err = pcall(run)
  assert(not ok and err == exec_error and #picks == 0)
end)
