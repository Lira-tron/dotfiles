-- tmux (~/.config/tmux/tmux.conf)
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>m", "pane.zoom")

rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+a>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
rex.bind("repeat/m", "pane.zoom")

-- Herdr (~/.config/herdr/config.toml)
rex.bind("ctrl+a>,", "client.settings")
rex.bind("ctrl+a>shift+r", "client.config.reload")
rex.bind("ctrl+a>f", "session.switch")
rex.bind("ctrl+a>g", "session.switch")
rex.bind("ctrl+a>w", "session.switch")
rex.bind("ctrl+a>shift+s", "session.new")
rex.bind("ctrl+a>shift+w", "session.rename")
rex.bind("ctrl+a>shift+d", "session.close")
rex.bind("ctrl+a>c", "client.sidebar.activity.toggle")
rex.bind("ctrl+a>o", "client.tab.rename")
rex.bind("ctrl+a>shift+p", "client.tab.move", { direction = "backward" })
rex.bind("ctrl+a>shift+n", "client.tab.move", { direction = "forward" })
rex.bind("ctrl+a>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+a>2", "client.tab.goto", { index = 2 })
rex.bind("ctrl+a>3", "client.tab.goto", { index = 3 })
rex.bind("ctrl+a>4", "client.tab.goto", { index = 4 })
rex.bind("ctrl+a>5", "client.tab.goto", { index = 5 })
rex.bind("ctrl+a>6", "client.tab.goto", { index = 6 })
rex.bind("ctrl+a>7", "client.tab.goto", { index = 7 })
rex.bind("ctrl+a>8", "client.tab.goto", { index = 8 })
rex.bind("ctrl+a>9", "client.tab.goto", { index = 9 })
rex.bind("ctrl+a>shift+x", "client.tab.close")
rex.bind("ctrl+a>shift+o", "pane.rename")
rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+a>tab", "pane.focus_next")
rex.bind("ctrl+a>shift+tab", "pane.focus_previous")
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>x", "pane.close")
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>e", "client.sidebar.toggle")

rex.mode("resize", { exclusive = true })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")
rex.bind("ctrl+a>r", "client.mode.enter", { name = "resize" })
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })

-- Ghostty (~/.config/ghostty/config)
rex.bind("shift+cmd+v", "pane.split", { direction = "right" })
rex.bind("shift+cmd+m", "pane.zoom")
rex.bind("alt+m", "pane.zoom")
rex.bind("shift+cmd+a", "client.sidebar.activity.toggle")
rex.bind("shift+cmd+s", "session.switch")
rex.bind("shift+cmd+z", "session.undo_close")
rex.bind("shift+cmd+h", "pane.focus", { direction = "left" })
rex.bind("shift+cmd+j", "pane.focus", { direction = "down" })
rex.bind("shift+cmd+k", "pane.focus", { direction = "up" })
rex.bind("shift+cmd+l", "pane.focus", { direction = "right" })

rex.action({
  name = "session_close_confirm",
  title = "Close Session (Confirm)…",
  description = "Ask before closing the current session",
  run = function(ctx)
    local view = rex.session.view({ session_id = ctx.session_id })
    local label = view and view.label or "this session"
    local choice = rex.ui.pick({
      title = "Close " .. label .. "? Its programs will end.",
      items = {
        { id = "close", title = "Close session", icon = "document" },
        { id = "cancel", title = "Cancel" },
      },
    })
    if choice == "close" then
      rex.client.queue("session.close")
    end
  end,
})
rex.bind("shift+cmd+x", "session_close_confirm")

require("workspaces")

local REMOTE_PREFIX = "🥊-"

local function session_call(host, method, args)
  if host then
    return rex.server(host).call(method, args)
  end
  -- rex.call follows the focused pane's host. The CLI here runs on the home
  -- server, so "local" still means the Mac when a remote pane is selected.
  local result, err = rex.exec({
    "/bin/zsh", "-c",
    'unset REX_SERVER REX_SESSION REX_BLOCK REX_CLIENT; '
      .. 'export PATH="$PATH:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"; '
      .. 'exec rex "$@"',
    "rex", "api", "call", method, rex.json.encode(args or {}),
  })
  if not result then return nil, err end
  if not result.ok then return nil, result.stderr end
  return rex.json.decode(result.stdout)
end

local function append_sessions(items, host)
  local result, err = session_call(host, "session.list")
  if not result then
    if not host then error(err, 0) end
    rex.log("warn", "Could not list sessions on " .. host .. ": " .. err)
    return
  end
  for _, session in ipairs(result.sessions or {}) do
    items[#items + 1] = {
      id = session.session_id,
      title = session.label,
      subtitle = host or "This Mac",
      icon = host and "server" or "terminal",
    }
  end
end

local function create_session(host)
  local name = rex.ui.input({
    title = host and ("New session on " .. host) or "New local session",
    placeholder = "Session name",
    confirm = "Create session",
  })
  if name == nil then return end
  name = name:match("^%s*(.-)%s*$")
  if name == "" then return end
  if host and name:sub(1, #REMOTE_PREFIX) ~= REMOTE_PREFIX then
    name = REMOTE_PREFIX .. name
  end
  local created, err = session_call(host, "session.create", {
    label = name,
    initial_windows = {
      { layout = rex.layout.block({ flavor = "com.superlogical.terminal.shell" }) },
    },
  })
  if not created then error(err, 0) end
  rex.client.queue("session.select", { session_id = created.session_id })
end

rex.action({
  name = "session_picker_native",
  title = "Open Session (Custom Native)…",
  description = "Switch sessions or create a named local or remote session",
  run = function()
    local hosts = rex.servers()
    local items = {
      { id = "new_local", title = "New local session…", icon = "plus" },
      { id = "new_remote", title = "New remote session…", icon = "server" },
    }
    append_sessions(items)
    for _, host in ipairs(hosts) do
      append_sessions(items, host)
    end
    local choice = rex.ui.pick({ title = "Sessions", placeholder = "Filter sessions", items = items })
    if choice == nil then return end
    if choice == "new_local" then
      return create_session()
    end
    if choice == "new_remote" then
      if #hosts == 0 then error("No connected remote hosts are available.", 0) end
      local host_items = {}
      for _, host in ipairs(hosts) do
        host_items[#host_items + 1] = { id = host, title = host, icon = "server" }
      end
      local host = rex.ui.pick({ title = "Create session on host", items = host_items })
      if host == nil then return end
      return create_session(host)
    end
    rex.client.queue("session.select", { session_id = choice })
  end,
})

rex.bind("shift+cmd+f", "session_picker_native")
