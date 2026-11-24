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
