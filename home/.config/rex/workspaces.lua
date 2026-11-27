local fs = require("files")
local worktrees = require("worktree_actions")
local trees = require("worktrees")
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

local HELPER = os.getenv("HOME") .. "/.config/rex/worktree_command.lua"
local SESSION_MENU = {
  { id = "connect", title = "Open", icon = "branch" },
  { id = "delete_native", title = "Delete", subtitle = "Remove the worktree and close its session", icon = "document" },
  { id = "force_delete_native", title = "Force delete", subtitle = "Discard changes, remove the worktree and close its session", icon = "document" },
}

local function workspace_items(cwd)
  local items, by_id = {}, {}
  for line in worktrees.current(cwd):gmatch("[^\n]+") do
    local kind, title, value = line:match("^%[(%w+)%] (.-)\t(.+)$")
    if kind == "tree" and not by_id[value] then
      by_id[value] = {
        id = value,
        title = title:gsub("^(.-) · (.*)$", "%2 · %1"),
        path = trees.decode(value).path,
      }
      items[#items + 1] = by_id[value]
    end
  end
  worktrees.with_sessions(items)
  for _, item in ipairs(items) do
    item.icon = item.session_id and "terminal" or "folder"
    item.detail = item.session_id and "session" or "dir"
  end
  by_id.none = { id = "none", title = "New worktree…", icon = "plus", detail = "none" }
  table.insert(items, 1, by_id.none)
  return items, by_id
end

local function helper_argv(action, value, name, force)
  local args = { operation = action, value = value, name = name, force = force }
  return { "rex", "do", HELPER, "--args", rex.json.encode(args) }
end

local function workspace_operation(ctx, operation, value, name)
  -- Forward only host operations; waiting in a remote picker exceeds the call's 10s deadline.
  if ctx.server then
    local result, err = rex.call("client.action", {
      action = "workspace_picker_native",
      args = { operation = operation, value = value, name = name },
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
  if operation == "directories" then
    local directories = {}
    for line in fs.run({
      "/bin/zsh", "-c",
      'if [[ -d "${WORKPLACE_DIR:-$HOME/workplace}" ]]; then fd -t d -d 1 . "${WORKPLACE_DIR:-$HOME/workplace}" --format "{/}\t{}"; fi',
    }, cwd):gmatch("[^\n]+") do
      local label, path = line:match("^(.-)\t(.+)$")
      if path then directories[#directories + 1] = { name = label, title = label, path = path } end
    end
    return worktrees.with_sessions(directories)
  end
  if operation == "close_session" then
    assert(value:sub(1, 8) == "session:", "Choose a session to close.")
    return worktrees.delete(value, true)
  end
  if operation == "create" or operation == "delete_native" or operation == "force_delete_native" then
    local argv = helper_argv("delete-native", value, nil, operation == "force_delete_native")
    if operation == "create" then
      if not name or name == "" then error("A worktree name is required.", 0) end
      argv = helper_argv("create-named", value, name)
    end
    if ctx.session_id then
      argv[#argv + 1], argv[#argv + 2] = "--session", ctx.session_id
    end
    local process, err = rex.exec.start(argv, {
      cwd = cwd, env = fs.env(), detach = true, stdout = false, stderr = false,
    })
    if not process then error(err, 0) end
    return
  end
  if operation == "connect" then
    worktrees.connect(value)
    return
  end
  error("Unknown workspace operation: " .. tostring(operation), 0)
end

local function read_name()
  local name = rex.ui.input({ title = "Worktree name:", placeholder = "Worktree name", confirm = "Create" })
  if name == nil then return end
  name = name:match("^%s*(.-)%s*$")
  if name == "" then return end
  return name
end

rex.action({
  name = "workspace_picker_native",
  title = "Open Worktree (Native)…",
  description = "Pick a Git worktree in the command palette, then open, create, or remove it",
  args = { operation = "string?", value = "string?", name = "string?" },
  run = function(ctx, args)
    if args.operation then
      return workspace_operation(ctx, args.operation, args.value, args.name)
    end
    local choices = workspace_operation(ctx, "list")
    local value = rex.ui.pick({ title = "Worktrees", placeholder = "Filter", items = choices.items })
    if value == nil then
      return
    end
    local item = choices.by_id[value]
    if value == "none" then
      local name = read_name()
      if name == nil then return end
      return workspace_operation(ctx, "create", value, name)
    end
    local action = rex.ui.pick({ title = item.title, placeholder = "Action", items = SESSION_MENU })
    if action == nil then return end
    return workspace_operation(ctx, action, action == "connect" and item.session_id or value)
  end,
})

rex.action({
  name = "workspace_deletion_confirm",
  title = "Confirm Worktree Deletion",
  args = { message = "string", force = "boolean?" },
  run = function(_, args)
    local choice = rex.ui.pick({
      title = args.force and "Force delete worktree?" or "Delete worktree?",
      items = {
        { id = "cancel", title = "No" },
        { id = "delete", title = "Yes", subtitle = args.message, icon = "document" },
      },
    })
    return choice == "delete" and "ok" or "cancel"
  end,
})

rex.action({
  name = "workspace_operation_failed",
  title = "Worktree Operation Failed",
  args = { message = "string", operation = "string" },
  run = function(ctx, args)
    local title = args.operation == "delete" and "Worktree deletion failed" or "Worktree creation failed"
    local layer, err = rex.session.new_layer({
      session_id = ctx.session_id,
      bounds = { 0.15, 0.2, 0.7, 0.6 },
      focus = true,
      layout = rex.layout.block({
        flavor = TERMINAL .. ".shell",
        label = title,
        options = {
          shell = "none",
          command = {
            "/bin/sh", "-c",
            [[printf '\033[1;31m%s\033[0m\n\n%s\n\nPress Enter to close.\n' "$1" "$2"; IFS= read -r answer]],
            "rex-error", title, args.message,
          },
          exit = { on_completion = true },
        },
      }),
    })
    if not layer then error(tostring(err) .. "\n" .. args.message, 0) end
    return layer
  end,
})

rex.bind("ctrl+a>t", "workspace_picker_native")
rex.bind("shift+cmd+t", "workspace_picker_native")

return workspace_operation
