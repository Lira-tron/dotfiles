local workspace_operation = require("workspaces")

local function session_command(args)
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
  local args = { "do", "session.select", "session_id=" .. created.session_id }
  if host then
    table.insert(args, 1, host)
    table.insert(args, 1, "-S")
  end
  session_command(args)
end

local function pick(ctx)
  local choices = items()
  for _, directory in ipairs(workspace_operation(ctx, "directories")) do
    choices[#choices + 1] = {
      id = "dir:" .. directory.path,
      title = directory.name,
      subtitle = (ctx.server and ctx.server .. " · " or "") .. directory.path,
      icon = "folder",
    }
  end
  local choice = rex.ui.pick({ title = "Sessions", items = choices })
  if choice == nil then return end
  if choice:sub(1, 4) == "dir:" then return workspace_operation(ctx, "connect", choice:sub(5)) end
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
