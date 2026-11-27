-- Run from the Rex config directory: lua tests/test_sessions.lua
local sessions, calls, picks, inputs, selections, prompt_order
local hosts, choice, name, create_error, exec_error, select_error, encoded, response
local answers, close_error, listed, list_error, closed
local ctx, workspace_calls, directory_rows
local source = arg[1] or "sessions.lua"

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
  answers, close_error = nil, nil
  listed, list_error, closed = { local_mac = {}, lyhost = {}, devbox = {} }, nil, {}
  ctx, workspace_calls = { server = "lyhost", session_id = "session:test", block_id = "block:test" }, {}
  directory_rows = { { name = "project", title = "project", path = "/tmp/my projects/project/" } }
  rex = {
    servers = function() return hosts end,
    server = function(host)
      return { call = function(method, args)
        if method == "session.list" then
          if list_error then return nil, list_error end
          return { sessions = listed[host] or {} }
        end
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
        if argv[7] == "session.list" then
          response = { sessions = listed.local_mac }
          return { ok = true, stdout = "response" }
        end
        local err
        response, err = create("local", argv[7], encoded)
        return { ok = response ~= nil, stdout = "response", stderr = err }
      end
      local host, offset = "local", 5
      if argv[offset] == "-S" then host, offset = argv[offset + 1], offset + 2 end
      if argv[offset] == "session" then
        assert(argv[offset + 1] == "kill")
        if close_error then return { ok = false, stderr = close_error } end
        closed[#closed + 1] = { host = host, session_id = argv[offset + 2] }
        return { ok = true, stdout = "" }
      end
      assert(argv[offset] == "do" and argv[offset + 1] == "session.select")
      if select_error then return { ok = false, stderr = select_error } end
      local id = argv[offset + 2]:match("^session_id=(.+)$")
      local exists = id == "session:new-" .. host
      for _, session in ipairs(listed[host == "local" and "local_mac" or host] or {}) do
        exists = exists or id == session.session_id
      end
      if not exists then
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
    assert(operation == "connect" or operation == "close_session")
    if operation == "close_session" and close_error then error(close_error, 0) end
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
  assert(items[2].id == "remote:lyhost" and items[2].title == "🥊-New Session...")
  assert(items[2].subtitle == "lyhost")
  assert(items[3].id == "remote:devbox" and items[3].title == "🥊-New Session...")
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
    assert(#picks == 1 and #picks[1].items == 4, "no extra host or worktree menu")
    assert(picks[1].items[1].title == "New Session..." and picks[1].items[1].subtitle == "This Mac")
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

test("directory shortcuts are in the session menu and open on the pane's host", function()
  choice = "dir:/tmp/my projects/project/"
  sessions.pick(ctx)
  local directory = picks[1].items[4]
  assert(directory.title == "project" and directory.icon == "folder" and directory.detail == "dir")
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
  assert(#picks[1].items == 3)
end)

test("a folder session replaces its directory row and opens the existing session", function()
  directory_rows[1].session_id, directory_rows[1].title = "session:renamed", "My renamed session"
  listed.lyhost = { { session_id = "session:renamed", label = "My renamed session" } }
  answers = { "remote:lyhost/session:renamed", "connect" }
  sessions.pick(ctx)
  local entry = picks[1].items[4]
  assert(#picks[1].items == 4 and entry.title == "My renamed session" and entry.detail == "session")
  assert(entry.subtitle == "lyhost" and entry.icon == "terminal")
  assert(#picks == 2 and #picks[2].items == 2 and #inputs == 0)
  assert(picks[2].items[1].title == "Open" and picks[2].items[2].title == "Close session")
  assert(#workspace_calls == 1 and #selections == 1)
  assert(selections[1].host == "lyhost" and selections[1].session_id == "session:renamed")
end)

test("deleting a folder session closes it only after confirmation and keeps the directory", function()
  for _, reply in ipairs({ false, "cancel", "delete" }) do
    setup()
    directory_rows[1].session_id, directory_rows[1].title = "session:folder", "Folder session"
    listed.lyhost = { { session_id = "session:folder", label = "Folder session" } }
    answers = { "remote:lyhost/session:folder", "delete", reply }
    sessions.pick(ctx)
    assert(#picks == 3 and #inputs == 0)
    assert(picks[3].title == "Close Folder session on lyhost?")
    assert(picks[3].items[2].subtitle == "Folder session")
    if reply == "delete" then
      assert(#closed == 1 and closed[1].host == "lyhost" and closed[1].session_id == "session:folder")
    else
      assert(#closed == 0)
    end
    assert(#calls == 0 and #workspace_calls == 1)
  end
end)

test("cancelling a folder session action leaves it alone", function()
  directory_rows[1].session_id = "session:folder"
  listed.lyhost = { { session_id = "session:folder", label = "Folder session" } }
  answers = { "remote:lyhost/session:folder" }
  sessions.pick(ctx)
  assert(#picks == 2 and #workspace_calls == 1 and #inputs == 0)
end)

test("directory session deletion errors do not fall back to a different host", function()
  directory_rows[1].session_id = "session:folder"
  listed.lyhost = { { session_id = "session:folder", label = "Folder session" } }
  answers, close_error = { "remote:lyhost/session:folder", "delete", "delete" }, "Could not close session"
  local ok, err = pcall(sessions.pick, ctx)
  assert(not ok and err == close_error)
  assert(#workspace_calls == 1 and #closed == 0 and #calls == 0)
end)

test("all sessions are listed independently of directories with type details and unchanged titles", function()
  listed.local_mac = { { session_id = "session:mac", label = "Notes" } }
  listed.lyhost = { { session_id = "session:remote", label = "Build" } }
  listed.devbox = { { session_id = "session:other", label = "Browser only" } }
  choice = nil
  sessions.pick(ctx)
  local found = {}
  for _, item in ipairs(picks[1].items) do found[item.id] = item end
  assert(#picks[1].items == 7)
  assert(found["local/session:mac"].title == "Notes")
  assert(found["local/session:mac"].detail == "session")
  assert(found["local/session:mac"].subtitle == "This Mac")
  assert(found["remote:lyhost/session:remote"].subtitle == "lyhost")
  assert(found["remote:devbox/session:other"].title == "Browser only")
  assert(found["remote:devbox/session:other"].detail == "session")
  assert(found["dir:/tmp/my projects/project/"].title == "project")
  assert(found["dir:/tmp/my projects/project/"].detail == "dir")
  for _, id in ipairs({ "local", "remote:lyhost", "remote:devbox" }) do
    assert(found[id].detail == nil, "creation actions must not carry a session type tag")
  end
end)

test("multiple sessions in one directory remain visible without duplicate directory or session entries", function()
  listed.lyhost = {
    { session_id = "session:a", label = "First" },
    { session_id = "session:b", label = "Second" },
  }
  directory_rows[1].session_id = "session:a"
  directory_rows[2] = { path = "/tmp/project-alias", title = "Alias", session_id = "session:a" }
  choice = nil
  sessions.pick(ctx)
  assert(#picks[1].items == 5)
  local seen = {}
  for _, item in ipairs(picks[1].items) do
    assert(not seen[item.id] and not item.id:match("^dir:"))
    seen[item.id] = true
  end
  assert(seen["remote:lyhost/session:a"] and seen["remote:lyhost/session:b"])
end)

test("the focused remote host is listed even when absent from configured hosts", function()
  hosts = {}
  listed.lyhost = { { session_id = "session:focus", label = "Focused host" } }
  choice = nil
  sessions.pick(ctx)
  assert(#picks[1].items == 4)
  assert(picks[1].items[3].id == "remote:lyhost/session:focus")
end)

test("a matching local session hides its directory and opens locally from the Mac", function()
  ctx.server = nil
  listed.local_mac = { { session_id = "session:mac", label = "Local project" } }
  directory_rows[1].session_id = "session:mac"
  answers = { "local/session:mac", "connect" }
  sessions.pick(ctx)
  assert(#picks[1].items == 4 and picks[1].items[4].title == "Local project")
  assert(#selections == 1 and selections[1].host == "local" and #calls == 0)
end)

test("a session discovered during directory scanning is added once", function()
  directory_rows[1].session_id, directory_rows[1].title = "session:late", "New arrival"
  directory_rows[2] = { path = "/tmp/alias", session_id = "session:late", title = "New arrival" }
  choice = nil
  sessions.pick(ctx)
  assert(#picks[1].items == 4)
  assert(picks[1].items[4].id == "remote:lyhost/session:late")
  assert(picks[1].items[4].title == "New arrival")
end)

test("sessions with the same label open and close on their own host", function()
  for _, host in ipairs({ "local", "lyhost", "devbox" }) do
    for _, action in ipairs({ "connect", "delete" }) do
      setup()
      for _, key in ipairs({ "local_mac", "lyhost", "devbox" }) do
        listed[key] = { { session_id = "session:same", label = "Same name" } }
      end
      local id = (host == "local" and "local" or "remote:" .. host) .. "/session:same"
      answers = { id, action, "delete" }
      sessions.pick(ctx)
      local result = action == "connect" and selections or closed
      assert(#result == 1 and result[1].host == host and result[1].session_id == "session:same")
      assert(#calls == 0 and #inputs == 0 and #workspace_calls == 1)
    end
  end
end)

test("remote listing failures are surfaced without opening an incomplete picker", function()
  list_error = "Remote host unavailable"
  local ok, err = pcall(sessions.pick, ctx)
  assert(not ok and err == list_error and #picks == 0 and #calls == 0)
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
