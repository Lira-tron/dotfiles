-- Run from the repository root: lua tests/test_init.lua
local actions, bindings = {}, {}
local create_new = function() end
local previous = package.loaded.workspaces
package.loaded.workspaces = create_new
rex = {
  action = function(value) actions[value.name] = value end,
  bind = function(key, value) bindings[key] = value end,
  mode = function() end,
}
dofile(arg[1] or "home/.config/rex/init.lua")
package.loaded.workspaces = previous
assert(bindings["shift+cmd+n"] == "create_session")
assert(actions.create_session.run == create_new)
assert(bindings["shift+cmd+s"] == "session.switch")
assert(bindings["shift+cmd+a"] == "client.sidebar.activity.toggle")
assert(bindings["ctrl+a>shift+s"] == "session.new")
assert(bindings["ctrl+a>f"] == "session.switch")
assert(bindings["ctrl+a>g"] == "session.switch")
assert(bindings["ctrl+a>w"] == "session.switch")
print("PASS: creation uses the shared New menu and existing session shortcuts stay intact")
