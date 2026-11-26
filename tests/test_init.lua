-- Run from the repository root: lua tests/test_init.lua
local actions, bindings = {}, {}
local pick_session = function() end
local previous_workspaces, previous_sessions = package.loaded.workspaces, package.loaded.sessions
package.loaded.workspaces = true
package.loaded.sessions = { pick = pick_session }
rex = {
  action = function(value) actions[value.name] = value end,
  bind = function(key, value) bindings[key] = value end,
  mode = function() end,
}
dofile(arg[1] or "home/.config/rex/init.lua")
package.loaded.workspaces, package.loaded.sessions = previous_workspaces, previous_sessions
assert(bindings["shift+cmd+n"] == "create_session")
assert(actions.create_session.run == pick_session)
assert(actions.create_session.title == "Create Session…")
assert(bindings["shift+cmd+s"] == "session.switch")
assert(bindings["shift+cmd+a"] == "client.sidebar.activity.toggle")
assert(bindings["ctrl+a>shift+s"] == "session.new")
assert(bindings["ctrl+a>f"] == "session.switch")
assert(bindings["ctrl+a>g"] == "session.switch")
assert(bindings["ctrl+a>w"] == "session.switch")
print("PASS: session creation uses its own picker and existing shortcuts stay intact")
