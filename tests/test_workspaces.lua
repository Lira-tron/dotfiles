-- Run from the repository root: lua tests/test_workspaces.lua
local actions, calls, commands, starts, picks
local ctx, remote_error, failed_operation, selection, menu_action, picked, layer
local remote_call, elapsed, pick_hosts
local inputs, name, start_error, prompt_order
local source = arg[1] or "home/.config/rex/workspaces.lua"
local foreign_cwd = "/workplace/someone/Example/src/Example/dotfiles/dotfiles"

local function setup(remote)
  actions, calls, commands, starts, picks = {}, {}, {}, {}, {}
  ctx = { session_id = "session:test", block_id = "block:test", server = remote and "devbox" or nil }
  remote_error, failed_operation, remote_call = nil, nil, false
  elapsed, pick_hosts = 0, {}
  selection, menu_action, picked, layer = nil, nil, false, nil
  inputs, name, start_error = {}, "feature-work", nil
  prompt_order = {}
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
        return nil, "python3: working directory: stat " .. foreign_cwd .. ": no such file or directory"
      end
      assert(opts.cwd == (remote and foreign_cwd or "/tmp/project"), "helper lost the pane's working directory")
      if argv[1] == "/bin/zsh" then
        assert(argv[3]:find("WORKPLACE_DIR", 1, true), "directories must honor the configured root")
        return { ok = true, stdout = "project\t/tmp/my projects/project/\n" }
      end
      assert(argv[2] == os.getenv("HOME") .. "/.config/television/cable/rex-worktrees.py")
      return { ok = true, stdout = "[tree] ExampleService · feature-branch\ttree-id\n" }
    end,
  })
  rex = {
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
      if picked then return menu_action end
      picked = true
      return selection
    end },
    layout = { block = function(opts) return opts end },
    session = { new_layer = function(opts)
      layer = opts
      return { block_ids = { "block:created" } }
    end },
  }
  dofile(source)
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
  assert(calls[2].args.args.value == selection)
  assert(calls[2].args.session_id == ctx.session_id and calls[2].args.block_id == ctx.block_id)
  local command = commands[#commands]
  assert(command.remote and command.argv[3] == "connect" and command.argv[4] == selection)
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

test("remote delete retains its interactive confirmation shell", function()
  for _, operation in ipairs({ "delete", "force_delete" }) do
    setup(true)
    selection, menu_action = "tree-id", operation
    run()
    assert(#calls == 2 and calls[2].args.args.operation == operation)
    assert(layer.session_id == ctx.session_id)
    assert(layer.layout.options.cwd == foreign_cwd)
    local command = layer.layout.options.command
    assert(command[3] == (operation == "force_delete" and "delete" or operation))
    assert(command[4] == selection)
    assert(command[5] == (operation == "force_delete" and "--force" or nil))
    assert(#starts == 1 and starts[1].opts.detach)
  end
end)

test("the T picker lists only worktrees and worktree actions", function()
  setup(false)
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
  local command = commands[#commands].argv
  assert(command[3] == "connect" and command[4] == "/tmp/project")
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

test("new worktrees take native input and start detached on the pane's host", function()
  for _, remote in ipairs({ false, true }) do
    for _, target in ipairs({ "none", "tree-id" }) do
      setup(remote)
      selection, menu_action, name = target, "create", "  feature-work  "
      run()
      assert(#inputs == 1 and inputs[1].title == "Worktree name:")
      assert(inputs[1].confirm == "Create")
      assert(#picks == (target == "none" and 1 or 2), "no creation-type chooser")
      assert(prompt_order[#prompt_order] == "Worktree name:")
      assert(elapsed == (target == "none" and 60 or 75), "menus and input must permit user think-time")
      assert(layer == nil, "creation must not open a terminal overlay")
      assert(#starts == 1)
      local process = starts[1]
      assert(process.remote == remote)
      assert(process.argv[1] == "python3" and process.argv[2]:match("/rex%-worktrees.py$"))
      assert(process.argv[3] == "create-named" and process.argv[4] == target and process.argv[5] == "feature-work")
      assert(#process.argv == 5 and process.opts.detach)
      assert(process.opts.cwd == (remote and foreign_cwd or "/tmp/project"))
      if remote then
        assert(#calls == 2 and calls[2].args.args.name == "feature-work")
      end
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
  selection, start_error = "none", "Could not start python3"
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

test("background failures are displayed in a native prompt", function()
  setup(false)
  actions.workspace_creation_failed.run(ctx, { message = "Branch already exists" })
  assert(#picks == 1 and picks[1].title == "Worktree creation failed")
  assert(picks[1].items[1].subtitle == "Branch already exists")
  assert(layer == nil and #starts == 0)
end)
