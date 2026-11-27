local workspace_operation = require("workspaces")

local function session_command(args, host)
  if host then
    table.insert(args, 1, host)
    table.insert(args, 1, "-S")
  end
  local argv = {
    "/bin/zsh", "-c",
    'unset REX_SERVER REX_SESSION REX_BLOCK REX_CLIENT; '
      .. 'export PATH="$PATH:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"; '
      .. 'exec rex "$@"',
    "rex",
  }
  for _, value in ipairs(args) do argv[#argv + 1] = value end
  local result, err = rex.exec(argv)
  if not result then error(err, 0) end
  if not result.ok then error(result.stderr, 0) end
  return result.stdout
end

local function session_call(host, method, args)
  if not host then
    -- Local calls belong to the Mac even when the focused pane is remote.
    return rex.json.decode(session_command({ "api", "call", method, rex.json.encode(args or {}) }))
  end
  local result, err = rex.server(host).call(method, args or {})
  if not result then error(err, 0) end
  return result
end

local function items(ctx)
  local hosts = rex.servers()
  if ctx and ctx.server then
    local found = false
    for _, host in ipairs(hosts) do found = found or host == ctx.server end
    if not found then hosts[#hosts + 1] = ctx.server end
  end
  local choices = { { id = "local", title = "Create…", subtitle = "This Mac", icon = "plus" } }
  for _, host in ipairs(hosts) do
    choices[#choices + 1] = { id = "remote:" .. host, title = "🥊 Create remote…", subtitle = host, icon = "plus" }
  end
  local entries = {}
  local function add_session(session, host)
    local id = (host and "remote:" .. host or "local") .. "/" .. session.session_id
    if entries[id] then return end
    entries[id] = { session_id = session.session_id, label = session.label, host = host }
    choices[#choices + 1] = {
      id = id, title = "[session] " .. session.label,
      subtitle = host or "This Mac", icon = "terminal",
    }
  end
  for _, session in ipairs(session_call(nil, "session.list").sessions or {}) do
    add_session(session)
  end
  for _, host in ipairs(hosts) do
    for _, session in ipairs(session_call(host, "session.list").sessions or {}) do
      add_session(session, host)
    end
  end
  if ctx then
    for _, directory in ipairs(workspace_operation(ctx, "directories")) do
      if directory.session_id then
        add_session({ session_id = directory.session_id, label = directory.title }, ctx.server)
      else
        local id = "dir:" .. directory.path
        entries[id] = directory
        choices[#choices + 1] = {
          id = id, title = "[dir] " .. directory.title,
          subtitle = (ctx.server and ctx.server .. " · " or "") .. directory.path, icon = "folder",
        }
      end
    end
  end
  return choices, entries
end

local function create(choice, name)
  local host = choice ~= "local" and choice:sub(8) or nil
  local prefix = "🥊-"
  if host and name:sub(1, #prefix) ~= prefix then name = prefix .. name end
  local request = {
    label = name,
    initial_windows = {
      { layout = rex.layout.block({ flavor = "com.superlogical.terminal.shell" }) },
    },
  }
  local created = session_call(host, "session.create", request)
  -- session.select resolves IDs on the server that sent the client action.
  session_command({ "do", "session.select", "session_id=" .. created.session_id }, host)
end

local function confirm_delete(label, location)
  return rex.ui.pick({
    title = "Delete " .. label .. " on " .. location .. "?",
    items = {
      { id = "cancel", title = "No" },
      { id = "delete", title = "Yes", subtitle = label, icon = "document" },
    },
  }) == "delete"
end

local function pick(ctx)
  local choices, entries = items(ctx)
  local choice = rex.ui.pick({ title = "Sessions", placeholder = "Search session, dir, or name", items = choices })
  if choice == nil then return end
  if entries[choice] then
    local entry = entries[choice]
    if not entry.session_id then return workspace_operation(ctx, "connect", entry.path) end
    local action = rex.ui.pick({
      title = entry.label,
      items = {
        { id = "connect", title = "Open", icon = "terminal" },
        { id = "delete", title = "Delete", subtitle = "Close the session; keep the directory", icon = "document" },
      },
    })
    if action == "connect" then
      return session_command({ "do", "session.select", "session_id=" .. entry.session_id }, entry.host)
    end
    if action == "delete" and confirm_delete(entry.label, entry.host or "This Mac") then
      return session_command({ "session", "kill", entry.session_id }, entry.host)
    end
    return
  end
  local name = rex.ui.input({
    title = choice == "local" and "Session:" or choice:sub(8) .. " session:",
    placeholder = "Session name",
    confirm = "Create",
  })
  if name == nil then return end
  name = name:match("^%s*(.-)%s*$")
  if name == "" then return end
  return create(choice, name)
end

return { items = items, create = create, pick = pick }
