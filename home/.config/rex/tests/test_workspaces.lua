-- Run from the Rex config directory: lua tests/test_workspaces.lua
local actions, calls, commands, starts, picks
local ctx, remote_error, failed_operation, selection, menu_action, picked, layer
local remote_call, elapsed, pick_hosts
local inputs, name, start_error, prompt_order, tree_rows, encoded
local tree_sessions, layer_error
local source = arg[1] or "workspaces.lua"
local foreign_cwd = "/workplace/someone/Example/src/Example/dotfiles/dotfiles"

local function setup(remote)
  actions, calls, commands, starts, picks = {}, {}, {}, {}, {}
  ctx = { session_id = "session:test", block_id = "block:test", server = remote and "devbox" or nil }
  remote_error, failed_operation, remote_call = nil, nil, false
  elapsed, pick_hosts = 0, {}
  selection, menu_action, picked, layer = nil, nil, false, nil
  inputs, name, start_error = {}, "feature-work", nil
  prompt_order, encoded = {}, {}
  tree_rows = "[tree] ExampleService · feature-branch\ttree-id\n"
  tree_sessions = { ["tree-id"] = { session_id = "session:tree", label = "Renamed session" } }
  layer_error = nil
  local exec = setmetatable({
    start = function(argv, opts)
      starts[#starts + 1] = { argv = argv, opts = opts, remote = remote_call }
      if start_error then return nil, start_error end
      return { wait = function() error("Creation must outlive the remote action deadline") end }
    end,
  }, {
    __call = function(_, argv, opts)
      commands[#commands + 1] = { argv = argv, opts = opts, remote = remote_call }
      if argv[1] == "/bin/zsh" and argv[3] == "print -r -- $PATH" then
        return { ok = true, stdout = "/usr/bin:/bin\n" }
      end
      if remote and not remote_call then
        return nil, "working directory: stat " .. foreign_cwd .. ": no such file or directory"
      end
      assert(opts.cwd == (remote and foreign_cwd or "/tmp/project"), "helper lost the pane's working directory")
      if argv[1] == "/bin/zsh" then
        assert(argv[3]:find("WORKPLACE_DIR", 1, true), "directories must honor the configured root")
        return { ok = true, stdout = "project\t/tmp/my projects/project/\n" }
      end
      error("Unexpected command: " .. table.concat(argv, " "))
    end,
  })
  rex = {
    json = { encode = function(value)
      encoded[#encoded + 1] = value
      return tostring(#encoded)
    end },
    action = function(action) actions[action.name] = action end,
    bind = function() end,
    call = function(method, args)
      calls[#calls + 1] = { method = method, args = args }
      assert(method == "client.action")
      assert(args.server == nil, "forwarded action must execute locally on the destination")
      if remote_error and (not failed_operation or args.args.operation == failed_operation) then
        return nil, remote_error
      end
      local started = elapsed
      remote_call = true
      local ok, result = pcall(actions[args.action].run, {
        session_id = args.session_id, block_id = args.block_id,
      }, args.args or {})
      remote_call = false
      if not ok then return nil, result end
      -- Rex gives a forwarded call 10 seconds, even if its action is waiting for a picker.
      if elapsed - started > 10 then
        return nil, 'client.action: no reply from "devbox" within 10s'
      end
      return { result = result, client_actions = {} }
    end,
    block = { call = function()
      return { foreground = { cwd = remote and foreign_cwd or "/tmp/project" } }
    end },
    exec = exec,
    ui = { input = function(opts)
      inputs[#inputs + 1] = opts
      prompt_order[#prompt_order + 1] = opts.title
      assert(not remote_call, "name entry must not wait inside a forwarded call")
      elapsed = elapsed + 45
      return name
    end, pick = function(opts)
      picks[#picks + 1] = opts
      prompt_order[#prompt_order + 1] = opts.title
      pick_hosts[#pick_hosts + 1] = remote_call and "remote" or "local"
      elapsed = elapsed + 15
      local answer = selection
      if picked then answer = menu_action end
      picked = true
      if answer then
        local offered = false
        for _, item in ipairs(opts.items) do if item.id == answer then offered = true end end
        assert(offered, "picker returned an action that was not offered: " .. answer)
      end
      return answer
    end },
    layout = { block = function(opts) return opts end },
    session = { new_layer = function(opts)
      if layer_error then return nil, layer_error end
      layer = opts
      return { block_ids = { "block:created" } }
    end },
  }
  local old_files, old_actions, old_trees = package.loaded.files, package.loaded.worktree_actions, package.loaded.worktrees
  package.loaded.worktrees = { decode = function(value) return { path = "/" .. value } end }
  package.loaded.files = {
    env = function() return { PATH = "/usr/bin:/bin" } end,
    run = function(argv, cwd)
      local result, err = rex.exec(argv, { cwd = cwd })
      if not result then error(err, 0) end
      return result.stdout
    end,
  }
  package.loaded.worktree_actions = {
    current = function(cwd)
      commands[#commands + 1] = { operation = "current", remote = remote_call, cwd = cwd }
      assert(not remote or remote_call, "discovery ran on the wrong host")
      return tree_rows
    end,
    connect = function(value)
      commands[#commands + 1] = { operation = "connect", value = value, remote = remote_call }
    end,
    with_sessions = function(items)
      for _, item in ipairs(items) do
        local session = tree_sessions[item.id or item.path]
        if session then item.session_id, item.title = session.session_id, session.label end
      end
      return items
    end,
    delete = function(value, force)
      commands[#commands + 1] = { operation = "delete", value = value, force = force, remote = remote_call }
    end,
  }
  dofile(source)
  package.loaded.files, package.loaded.worktree_actions, package.loaded.worktrees = old_files, old_actions, old_trees
end

local function run(args)
  return actions.workspace_picker_native.run(ctx, args or {})
end

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL: " .. name .. ": " .. tostring(err) .. "\n")
    os.exit(1)
  end
  print("PASS: " .. name)
end

test("remote list can remain open for 15 seconds and then be cancelled", function()
  setup(true)
  run()
  assert(elapsed == 15 and #picks == 1 and layer == nil)
  assert(pick_hosts[1] == "local", "the picker must not wait inside the forwarded call")
  for _, command in ipairs(commands) do
    assert(command.remote, "filesystem discovery must run on the pane's host")
  end
  assert(#calls == 1 and calls[1].method == "client.action")
  local request = calls[1].args
  assert(request.action == "workspace_picker_native")
  assert(request.args.operation == "list")
  assert(request.session_id == ctx.session_id and request.block_id == ctx.block_id)
  assert(picks[1].items[2].id == "tree-id")
end)

test("both remote menus can wait 15 seconds before opening the selection", function()
  setup(true)
  selection, menu_action = "tree-id", "connect"
  run()
  assert(elapsed == 30 and #picks == 2)
  assert(pick_hosts[1] == "local" and pick_hosts[2] == "local")
  assert(#calls == 2 and calls[2].args.args.operation == "connect")
  assert(calls[2].args.args.value == "session:tree")
  assert(calls[2].args.session_id == ctx.session_id and calls[2].args.block_id == ctx.block_id)
  local command = commands[#commands]
  assert(command.remote and command.operation == "connect" and command.value == "session:tree")
  assert(picks[1].items[2].title == "Renamed session" and #picks[1].items == 2)
  assert(#picks[2].items == 3 and picks[2].items[1].title == "Open" and picks[2].items[2].title == "Delete")
  assert(picks[2].items[3].title == "Force delete")
  assert(layer == nil)
end)

test("cancelling the remote action menu does not open or change a worktree", function()
  setup(true)
  selection = "tree-id"
  run()
  assert(#picks == 2 and #calls == 1 and layer == nil)
end)

test("remote failure is reported without falling back to local execution", function()
  setup(true)
  remote_error = "Remote configuration needs reloading"
  local ok, err = pcall(run)
  assert(not ok and err == remote_error)
  assert(#commands == 0 and #picks == 0)
end)

test("failure opening the remote selection reaches the original action", function()
  setup(true)
  selection, menu_action = "tree-id", "connect"
  remote_error, failed_operation = "Remote session could not be opened", "connect"
  local ok, err = pcall(run)
  assert(not ok and err == remote_error)
  assert(#picks == 2 and #calls == 2 and layer == nil)
end)

test("deleting a tree session starts its native-confirmation helper on the owning host", function()
  for _, remote in ipairs({ false, true }) do
    setup(remote)
    selection, menu_action = "tree-id", "delete_native"
    run()
    if remote then assert(#calls == 2 and calls[2].args.args.operation == "delete_native") end
    assert(layer == nil and #starts == 1 and starts[1].remote == remote)
    assert(starts[1].opts.cwd == (remote and foreign_cwd or "/tmp/project"))
    local command = starts[1].argv
    assert(command[1] == "rex" and command[2] == "do")
    assert(command[3]:match("/worktree_command.lua$"))
    assert(command[4] == "--args" and #command == 7)
    assert(command[6] == "--session" and command[7] == ctx.session_id)
    local request = encoded[tonumber(command[5])]
    assert(request.operation == "delete-native" and request.value == selection)
    assert(request.force == false)
    assert(#starts == 1 and starts[1].opts.detach)
  end
end)

test("Force delete explicitly enables force in the native helper", function()
  setup(true)
  selection, menu_action = "tree-id", "force_delete_native"
  run()
  assert(calls[2].args.args.operation == "force_delete_native" and #starts == 1)
  local request = encoded[tonumber(starts[1].argv[5])]
  assert(request.operation == "delete-native" and request.value == selection and request.force == true)
end)

test("the T picker lists only worktrees and worktree actions", function()
  setup(false)
  tree_sessions = {}
  run()
  assert(#calls == 0 and #picks == 1 and layer == nil)
  assert(picks[1].items[1].id == "none")
  assert(picks[1].items[1].title == "New worktree…")
  assert(#picks[1].items == 2)
  assert(picks[1].items[2].id == "tree-id")
  assert(picks[1].items[2].title == "feature-branch · ExampleService")
  assert(picks[1].title == "Worktrees")
end)

test("opening a directory keeps the helper on the pane's host", function()
  setup(false)
  run({ operation = "connect", value = "/tmp/project" })
  local command = commands[#commands]
  assert(command.operation == "connect" and command.value == "/tmp/project")
  assert(layer == nil)
end)

test("directory discovery for the N picker runs on the pane's host", function()
  for _, remote in ipairs({ false, true }) do
    setup(remote)
    local result = run({ operation = "directories" })
    assert(#result == 1 and result[1].name == "project" and result[1].path == "/tmp/my projects/project/")
    assert(commands[#commands].remote == remote)
    assert(#picks == 0 and layer == nil and #starts == 0)
  end
end)

test("new worktrees take native input only from the first menu", function()
  for _, remote in ipairs({ false, true }) do
    setup(remote)
    selection, name = "none", "  feature-work  "
    run()
    assert(#inputs == 1 and inputs[1].title == "Worktree name:")
    assert(inputs[1].confirm == "Create")
    assert(#picks == 1, "no creation-type chooser")
    assert(prompt_order[#prompt_order] == "Worktree name:")
    assert(elapsed == 60, "menus and input must permit user think-time")
    assert(layer == nil, "creation must not open a terminal overlay")
    assert(#starts == 1)
    local process = starts[1]
    assert(process.remote == remote)
    assert(process.argv[1] == "rex" and process.argv[2] == "do" and process.argv[3]:match("/worktree_command.lua$"))
    local request = encoded[tonumber(process.argv[5])]
    assert(process.argv[4] == "--args" and request.operation == "create-named")
    assert(request.value == "none" and request.name == "feature-work")
    assert(#process.argv == 7 and process.opts.detach)
    assert(process.argv[6] == "--session" and process.argv[7] == ctx.session_id)
    assert(process.opts.cwd == (remote and foreign_cwd or "/tmp/project"))
    if remote then
      assert(#calls == 2 and calls[2].args.args.name == "feature-work")
    end
  end
end)

test("cancelled or empty worktree names never start creation", function()
  for _, value in ipairs({ false, "", " \t " }) do
    setup(true)
    selection, name = "none", value or nil
    run()
    assert(#inputs == 1 and #starts == 0 and #calls == 1 and layer == nil)
  end
end)

test("background launch errors reach the native caller", function()
  setup(true)
  selection, start_error = "none", "Could not start rex"
  local ok, err = pcall(run)
  assert(not ok and err == start_error and layer == nil)
end)

test("creation requests without a name fail before launching a background helper", function()
  for _, value in ipairs({ false, "" }) do
    setup(false)
    local ok, err = pcall(run, { operation = "create", value = "none", name = value or nil })
    assert(not ok and err == "A worktree name is required." and #starts == 0)
  end
end)

test("Open on a worktree without a session creates its session without asking for a name", function()
  for _, remote in ipairs({ false, true }) do
    setup(remote)
    selection, menu_action, tree_sessions = "tree-id", "connect", {}
    run()
    assert(#picks == 2 and #inputs == 0 and #starts == 0)
    assert(#picks[2].items == 3 and picks[2].items[1].title == "Open" and picks[2].items[2].title == "Delete")
    assert(picks[2].items[3].title == "Force delete")
    local command = commands[#commands]
    assert(command.operation == "connect" and command.value == "tree-id" and command.remote == remote)
  end
end)

test("directory session closure is forwarded to its host and rejects tree tokens", function()
  for _, remote in ipairs({ false, true }) do
    setup(remote)
    run({ operation = "close_session", value = "session:folder" })
    local command = commands[#commands]
    assert(command.operation == "delete" and command.value == "session:folder" and command.force)
    assert(command.remote == remote and #picks == 0)
    local ok = pcall(run, { operation = "close_session", value = "tree:not-a-session" })
    assert(not ok and commands[#commands] == command)
  end
end)

test("worktree confirmation offers only No and Yes with warnings in the subtitle", function()
  for _, force in ipairs({ false, true }) do
    for _, reply in ipairs({ false, "cancel", "delete" }) do
      setup(false)
      selection = reply or nil
      local message = "Delete /tmp/task\nThis removes all package branches.\nUncommitted changes will be discarded."
      local result = actions.workspace_deletion_confirm.run(ctx, { message = message, force = force })
      assert(result == (reply == "delete" and "ok" or "cancel"))
      assert(#picks == 1 and #picks[1].items == 2 and layer == nil)
      assert(picks[1].title == (force and "Force delete worktree?" or "Delete worktree?"))
      assert(picks[1].items[1].id == "cancel" and picks[1].items[1].title == "No")
      assert(picks[1].items[2].id == "delete" and picks[1].items[2].title == "Yes")
      assert(picks[1].items[2].subtitle == message)
    end
  end
end)

test("background failures open a floating error window with literal full text", function()
  for _, operation in ipairs({ "create", "delete" }) do
    setup(false)
    local message = "Operation failed\nDetails with 'quotes', $(echo literal), and `echo literal`"
    local result = actions.workspace_operation_failed.run(ctx, { operation = operation, message = message })
    local title = operation == "delete" and "Worktree deletion failed" or "Worktree creation failed"
    assert(#picks == 0 and #inputs == 0 and #starts == 0)
    assert(layer.session_id == ctx.session_id and layer.focus)
    assert(layer.layout.flavor == "com.superlogical.terminal.shell" and layer.layout.label == title)
    local options = layer.layout.options
    assert(options.shell == "none" and options.exit.on_completion)
    assert(options.command[1] == "/bin/sh" and options.command[2] == "-c")
    assert(options.command[5] == title and options.command[6] == message)
    assert(not options.command[3]:find(message, 1, true), "error text must be an argument, not shell code")
    assert(options.command[3]:find('read -r', 1, true))
    assert(result.block_ids[1] == "block:created")
  end
end)

test("failure to open the error window preserves the original failure", function()
  setup(false)
  layer_error = "Session unavailable"
  local ok, err = pcall(actions.workspace_operation_failed.run, ctx, { operation = "create", message = "Original failure" })
  assert(not ok and err == "Session unavailable\nOriginal failure")
  assert(#picks == 0 and layer == nil)
end)

test("numeric and boolean-looking names are passed as JSON strings", function()
  for _, value in ipairs({ "00123", "true", "false" }) do
    setup(true)
    selection, name = "none", value
    run()
    local argv = starts[1].argv
    assert(argv[4] == "--args" and encoded[tonumber(argv[5])].name == value)
  end
end)
