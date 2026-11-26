local fs = require("files")
local trees = require("worktrees")
local M = {}

local function call(method, args)
  local result, err = rex.call(method, args)
  if not result then error(err, 0) end
  return result
end

function M.current(cwd)
  local rows = trees.current(cwd)
  return #rows > 0 and table.concat(rows, "\n") or "[none] No worktrees here\tnone"
end

function M.label(name, worktree, remote)
  local prefix = worktree and (remote and "🥊🌴-" or "🌴-") or (remote and "🥊-" or "")
  return name:sub(1, #prefix) == prefix and name or prefix .. name
end

function M.session_name(path)
  local current = fs.resolve(path)
  local basename = fs.name(current)
  while current ~= "/" do
    if fs.read(current .. "/packageInfo") then return fs.name(current) end
    current = fs.parent(current)
  end
  return basename
end

local function labelled(label)
  local found = {}
  for _, session in ipairs(call("session.list").sessions or {}) do
    if session.label == label then found[#found + 1] = session.session_id end
  end
  return found
end

local function select_session(id)
  -- Send selection through the host that owns the session.
  fs.run({ "rex", "do", "session.select", "session_id=" .. id })
end

function M.open(path, worktree)
  local remote = fs.trim(fs.run({ "uname", "-s" })) ~= "Darwin"
  local label = M.label(M.session_name(path), worktree, remote)
  local found = labelled(label)
  local id = found[1]
  if not id then
    id = call("session.create", {
      label = label,
      initial_windows = {
        { layout = rex.layout.block({ flavor = "com.superlogical.terminal.shell", options = { cwd = path } }) },
      },
    }).session_id
  end
  select_session(id)
end

function M.connect(value)
  if value:sub(1, 8) == "session:" then
    select_session(value)
  elseif value:sub(1, 1) == "/" then
    M.open(value, false)
  else
    M.open(trees.decode(value).path, true)
  end
end

function M.create(value, name, cwd)
  local selected
  if value:sub(1, 5) == "tree:" then
    selected = trees.decode(value)
  else
    local parent = trees.current_parent(cwd)
    selected = { parent = parent, path = parent }
  end
  local created = trees.create(selected, name)
  if created then M.open(created.path, true) end
end

function M.create_session(cwd)
  local hosts, host = rex.servers()
  if #hosts > 0 then
    local answer = fs.prompt("Create it on remote (" .. table.concat(hosts, ", ") .. ")? [Y/n]: "):lower()
    if answer ~= "n" and answer ~= "no" then
      if #hosts == 1 and (answer == "" or answer == "y" or answer == "yes") then answer = hosts[1] end
      for _, candidate in ipairs(hosts) do if answer == candidate then host = candidate end end
      if not host then error("Name one of the Rex hosts: " .. table.concat(hosts, ", "), 0) end
    end
  end
  local name = fs.prompt("New Rex session name (blank cancels): ")
  if name == "" then return end
  local command = { "rex" }
  if host then command[#command + 1], command[#command + 2] = "-S", host end
  local label = M.label(name, false, host ~= nil or fs.trim(fs.run({ "uname", "-s" })) ~= "Darwin")
  local list = {}
  for _, part in ipairs(command) do list[#list + 1] = part end
  list[#list + 1], list[#list + 2] = "ls", "--json"
  local listed = rex.json.decode(fs.run(list))
  local id
  for _, session in ipairs(listed.sessions or {}) do if session.label == label then id = session.session_id; break end end
  if not id then
    local create = {}
    for _, part in ipairs(command) do create[#create + 1] = part end
    create[#create + 1], create[#create + 2] = "new", label
    if not host then create[#create + 1], create[#create + 2] = "-c", cwd end
    create[#create + 1] = "--json"
    id = rex.json.decode(fs.run(create)).session_id
  end
  command[#command + 1], command[#command + 2], command[#command + 3] = "do", "session.select", "session_id=" .. id
  fs.run(command)
end

local function kill(ids)
  if #ids > 0 then
    local command = { "rex", "session", "kill" }
    for _, id in ipairs(ids) do command[#command + 1] = id end
    fs.run(command)
  end
end

function M.delete(value, force, confirm)
  if value:sub(1, 8) == "session:" then
    for _, session in ipairs(call("session.list").sessions or {}) do
      if session.session_id == value then
        if force or confirm("Close Rex session " .. session.label .. ". Its programs will end; files are kept.") then
          kill({ value })
        end
        return
      end
    end
    error("Session no longer exists: " .. value, 0)
  end
  if value:sub(1, 5) ~= "tree:" then return end
  local selected = trees.decode(value)
  local remote = fs.trim(fs.run({ "uname", "-s" })) ~= "Darwin"
  local label = M.label(M.session_name(selected.path), true, remote)
  local found = labelled(label)
  local removed = trees.delete(selected, force, function(message)
    if #found > 0 then message = "Rex session " .. label .. " will be closed.\n" .. message end
    return confirm(message)
  end)
  if removed and not fs.test("-e", selected.path) then kill(found) end
end

function M.native(operation, value, name, cwd)
  local ok, err = pcall(function()
    if operation == "create" then
      if type(name) ~= "string" then error("A worktree name is required.", 0) end
      M.create(value, name, cwd)
    elseif operation == "delete" and value:sub(1, 5) == "tree:" then
      M.delete(value, false, function(message)
        return rex.invoke("workspace_deletion_confirm", { message = message }) == "ok"
      end)
    else
      error("Choose a Git worktree to delete.", 0)
    end
  end)
  if not ok then
    rex.invoke("workspace_operation_failed", { operation = operation, message = tostring(err) })
    error(err, 0)
  end
end

function M.session_rows()
  local rows = {}
  for _, session in ipairs(call("session.list").sessions or {}) do
    rows[#rows + 1] = "[session] " .. session.label:gsub("[\t\n]", " "):gsub("'", "’")
      .. "\t" .. session.session_id
  end
  return table.concat(rows, "\n")
end

function M.preview(value)
  if value == "none" then return "No worktrees here. Press Enter or Ctrl+G to create one." end
  if value:sub(1, 8) == "session:" then
    local view = rex.json.decode(fs.run({ "rex", "session", "inspect", value, "--json" }))
    for _, window in ipairs(view.windows) do
      if window.window_id == view.active_window_id then
        local screen = fs.run({ "rex", "capture", "-s", value, "-b", window.focused_block_id, "--trim" })
        local lines = {}
        for line in (screen:gsub("\n$", "") .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
        return table.concat(lines, "\n", math.max(1, #lines - 199))
      end
    end
  elseif value:sub(1, 1) == "/" then
    return fs.run({ "eza", "-la", "--color=always", value })
  else
    local path = trees.decode(value).path
    return path .. "\n" .. fs.run({ "git", "-C", path, "status", "--short" })
      .. fs.run({ "git", "-C", path, "log", "--oneline", "-8", "--color=always" })
  end
end

return M
