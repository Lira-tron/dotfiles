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

rex.bind("ctrl+a>shift+t", "workspace_picker")

local HELPER = os.getenv("HOME") .. "/.config/television/cable/rex-worktrees.py"
local ICONS = { tree = "branch", dir = "folder" }
local MENUS = {
  tree = {
    { id = "connect", title = "Open", icon = "branch" },
    { id = "create", title = "New worktree…", icon = "plus" },
    { id = "delete", title = "Delete worktree…", icon = "document" },
    { id = "force_delete", title = "Force-delete worktree…", icon = "document" },
  },
  dir = {
    { id = "connect", title = "Open as session", icon = "folder" },
    { id = "create", title = "New worktree…", icon = "plus" },
  },
}

local REX_BIN = os.getenv("HOME")
  .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
local user_path

-- The Rex server's PATH lacks Homebrew, toolbox, and the rex CLI, which the helper runs.
local function exec_env()
  if not user_path then
    local result = rex.exec({ "/bin/zsh", "-c", "print -r -- $PATH" })
    user_path = ((result and result.ok) and result.stdout:gsub("%s+$", "") or os.getenv("PATH")) .. ":" .. REX_BIN
  end
  return { PATH = user_path }
end

local function exec_lines(argv, cwd)
  local result, err = rex.exec(argv, { cwd = cwd, env = exec_env() })
  if not result then
    error(err, 0)
  end
  if not result.ok then
    error(result.stderr ~= "" and result.stderr or table.concat(argv, " ") .. " failed", 0)
  end
  return result.stdout:gmatch("[^\n]+")
end

local function workspace_items(cwd)
  local items, by_id = {}, {}
  -- Always offered first; the helper's own empty-list placeholder uses the same id and is skipped.
  by_id.none = { id = "none", title = "New worktree…", icon = "plus", detail = "none" }
  items[1] = by_id.none
  local sources = {
    { "python3", HELPER, "current" },
    { "fd", "-t", "d", "-d", "1", ".", os.getenv("HOME") .. "/workplace", "--format", "[dir] {/}\t{}" },
  }
  for _, argv in ipairs(sources) do
    for line in exec_lines(argv, cwd) do
      local kind, title, value = line:match("^%[(%w+)%] (.-)\t(.+)$")
      if kind and not by_id[value] then
        by_id[value] = {
          id = value,
          -- Put the worktree first so it stays visible in Rex's narrow native picker.
          -- To restore "repository · worktree", uncomment this and remove the next title line:
          -- title = title,
          title = kind == "tree" and title:gsub("^(.-) · (.*)$", "%2 · %1") or title,
          subtitle = kind == "dir" and value or nil,
          icon = ICONS[kind] or "plus",
          detail = kind,
        }
        items[#items + 1] = by_id[value]
      end
    end
  end
  return items, by_id
end

local function helper_argv(action, value)
  if action == "force_delete" then
    return { "python3", HELPER, "delete", value, "--force" }
  end
  return { "python3", HELPER, action, value }
end

local function workspace_operation(ctx, operation, value)
  -- Forward only host operations; waiting in a remote picker exceeds the call's 10s deadline.
  if ctx.server then
    local result, err = rex.call("client.action", {
      action = "workspace_picker_native",
      args = { operation = operation, value = value },
      session_id = ctx.session_id,
      block_id = ctx.block_id,
    })
    if err then
      error(err, 0)
    end
    return result.result
  end
  local cwd = pane_cwd(ctx)
  if operation == "list" then
    local items, by_id = workspace_items(cwd)
    return { items = items, by_id = by_id }
  end
  -- Delete and create confirm and read names from a terminal, so they run in a floating shell.
  if operation == "connect" then
    exec_lines(helper_argv(operation, value), cwd)
    return
  end
  local layer, err = rex.session.new_layer({
    session_id = ctx.session_id,
    bounds = { 0.2, 0.2, 0.6, 0.5 },
    focus = true,
    layout = rex.layout.block({
      flavor = TERMINAL .. ".shell",
      options = { command = helper_argv(operation, value), cwd = cwd },
    }),
  })
  if not layer then
    error(err, 0)
  end
  -- Closing the palette hands focus back to the pane it opened over, after the layer took it.
  local refocus = ("rex.session.focus_block({ block_id = %q })"):format(layer.block_ids[1])
  rex.exec.start(
    { "/bin/sh", "-c", 'sleep 0.3; exec "$0" do -s "$1" -e "$2"', "rex", ctx.session_id, refocus },
    { detach = true, stdout = false, stderr = false, env = exec_env() }
  )
  return layer
end

rex.action({
  name = "workspace_picker_native",
  title = "Open Worktree or Directory (Native)…",
  description = "Pick a Git worktree or directory in the command palette, then open, create, or remove it",
  args = { operation = "string?", value = "string?" },
  run = function(ctx, args)
    if args.operation then
      return workspace_operation(ctx, args.operation, args.value)
    end
    local choices = workspace_operation(ctx, "list")
    local value = rex.ui.pick({ title = "Worktrees and directories", placeholder = "Filter", items = choices.items })
    if value == nil then
      return
    end
    local item = choices.by_id[value]
    local kind = item.detail
    local action = "create"
    if MENUS[kind] then
      action = rex.ui.pick({ title = item.title, placeholder = "Action", items = MENUS[kind] })
      if action == nil then
        return
      end
    end
    return workspace_operation(ctx, action, value)
  end,
})

rex.bind("ctrl+a>t", "workspace_picker_native")
