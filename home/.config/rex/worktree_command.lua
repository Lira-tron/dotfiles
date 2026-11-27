-- Entry point for detached native operations and the optional Television channel.
local directory = debug.getinfo(1, "S").source:gsub("^@", ""):match("(.*/)")
package.path = directory .. "?.lua;" .. package.path
local fs = require("files")
local actions = require("worktree_actions")
local args = rex.args
local operation, value = args.operation, args.value or "none"
local cwd = fs.trim(fs.run({ "pwd", "-P" }))

local function confirm(message)
  io.stderr:write(message .. "\n")
  return fs.prompt("Type ok to delete (blank cancels): ") == "ok"
end

if operation == "current" then
  print(actions.current(cwd))
elseif operation == "sessions" then
  print(actions.session_rows())
elseif operation == "preview" then
  print(actions.preview(value))
elseif operation == "create-named" then
  actions.native("create", value, args.name, cwd)
elseif operation == "delete-native" then
  actions.native("delete", value, nil, cwd, args.force)
elseif operation == "delete" then
  actions.delete(value, args.force, confirm)
elseif operation == "create" or (operation == "connect" and value == "none") then
  if value:sub(1, 8) == "session:" then
    actions.create_session(cwd)
  else
    actions.create(value, nil, cwd)
  end
elseif operation == "connect" then
  actions.connect(value)
else
  error("Unknown Rex worktree action: " .. tostring(operation), 0)
end
