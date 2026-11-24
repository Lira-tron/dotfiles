local TERMINAL = "com.superlogical.terminal"

local function pane_cwd(ctx)
  if not ctx.block_id then
    return nil
  end
  local process = rex.block.call(TERMINAL, "process", { block_id = ctx.block_id })
  if not process then
    return nil
  end
  return (process.foreground and process.foreground.cwd) or process.home
end

rex.action({
  name = "workspace_picker",
  title = "Open Worktree or Session…",
  description = "Pick a Git worktree, directory, or session in Television and switch to its Rex session",
  run = function(ctx)
    local layer, err = rex.session.new_layer({
      session_id = ctx.session_id,
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block({
        flavor = TERMINAL .. ".shell",
        options = { command = { "tv", "rex-workspaces" }, cwd = pane_cwd(ctx) },
      }),
    })
    if not layer then
      error(err, 0)
    end
    return layer
  end,
})

rex.bind("ctrl+a>t", "workspace_picker")
