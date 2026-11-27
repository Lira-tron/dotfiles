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

local function items()
  local choices = { { id = "local", title = "Create session", subtitle = "This Mac", icon = "terminal" } }
  for _, host in ipairs(rex.servers()) do
    choices[#choices + 1] = { id = "remote:" .. host, title = "🥊 Create remote session", subtitle = host, icon = "server" }
  end
  return choices
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
  local created, err
  if host then
    created, err = rex.server(host).call("session.create", request)
  else
    -- A local session belongs to the Mac even when the focused pane is remote.
    created = rex.json.decode(session_command({ "api", "call", "session.create", rex.json.encode(request) }))
  end
  if not created then error(err, 0) end
  -- session.select resolves IDs on the server that sent the client action.
  session_command({ "do", "session.select", "session_id=" .. created.session_id }, host)
end

local function confirm_delete(label, location)
  return rex.ui.pick({
    title = "Delete " .. label .. " on " .. location .. "?",
    items = {
      { id = "cancel", title = "No" },
      { id = "delete", title = "Yes", subtitle = "All its tabs and programs will close. Files are kept.", icon = "document" },
    },
  }) == "delete"
end

local function delete_session()
  local choices, targets = {}, {}
  for _, location in ipairs(items()) do
    local host = location.id ~= "local" and location.id:sub(8) or nil
    local listed = rex.json.decode(session_command({ "ls", "--json" }, host))
    for _, session in ipairs(listed.sessions) do
      local id = location.id .. "/" .. session.session_id
      choices[#choices + 1] = { id = id, title = session.label, subtitle = location.subtitle, icon = location.icon }
      targets[id] = { host = host, id = session.session_id, label = session.label, location = location.subtitle }
    end
  end
  local choice = rex.ui.pick({ title = "Delete session", placeholder = "Choose a session", items = choices })
  if choice == nil then return end
  local target = targets[choice]
  if not confirm_delete(target.label, target.location) then return end
  session_command({ "session", "kill", target.id }, target.host)
end

local function pick(ctx)
  local choices = items()
  local directories = {}
  choices[#choices + 1] = { id = "delete", title = "Delete session…", icon = "document" }
  for _, directory in ipairs(workspace_operation(ctx, "directories")) do
    local id = "dir:" .. directory.path
    directories[id] = directory
    choices[#choices + 1] = {
      id = id,
      title = directory.title,
      subtitle = not directory.session_id and ((ctx.server and ctx.server .. " · " or "") .. directory.path) or nil,
      icon = directory.session_id and "terminal" or "folder",
    }
  end
  local choice = rex.ui.pick({ title = "Sessions", items = choices })
  if choice == nil then return end
  if choice == "delete" then return delete_session() end
  if directories[choice] then
    local directory = directories[choice]
    if not directory.session_id then return workspace_operation(ctx, "connect", directory.path) end
    local action = rex.ui.pick({
      title = directory.title,
      items = {
        { id = "connect", title = "Open", icon = "terminal" },
        { id = "delete", title = "Delete", subtitle = "Close the session; keep the directory", icon = "document" },
      },
    })
    if action == "connect" then return workspace_operation(ctx, "connect", directory.session_id) end
    if action == "delete" and confirm_delete(directory.title, ctx.server or "This Mac") then
      return workspace_operation(ctx, "close_session", directory.session_id)
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
