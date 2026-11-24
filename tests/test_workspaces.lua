-- Run from the repository root: lua tests/test_workspaces.lua
local actions, calls, commands, starts, picks
local ctx, remote_result, remote_error, selection, menu_action, picked, layer
local source = arg[1] or "home/.config/rex/workspaces.lua"
local foreign_cwd = "/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles"

local function setup(remote)
  actions, calls, commands, starts, picks = {}, {}, {}, {}, {}
  ctx = { session_id = "session:test", block_id = "block:test", server = remote and "devbox" or nil }
  remote_result, remote_error = { forwarded = true }, nil
  selection, menu_action, picked, layer = nil, nil, false, nil
  local exec = setmetatable({
    start = function(argv, opts)
      starts[#starts + 1] = { argv = argv, opts = opts }
      return {}
    end,
  }, {
    __call = function(_, argv, opts)
      commands[#commands + 1] = { argv = argv, opts = opts }
      if argv[1] == "/bin/zsh" then
        return { ok = true, stdout = "/usr/bin:/bin\n" }
      end
      if remote then
        return nil, "python3: working directory: stat " .. foreign_cwd .. ": no such file or directory"
      end
      assert(opts.cwd == "/tmp/project", "helper lost the pane's working directory")
      if argv[1] == "fd" then
        assert(argv[7] == os.getenv("HOME") .. "/workplace", "directories must use this host's workplace")
        return { ok = true, stdout = "[dir] project\t/tmp/project\n" }
      end
      assert(argv[2] == os.getenv("HOME") .. "/.config/television/cable/rex-worktrees.py")
      return { ok = true, stdout = "[tree] feature\ttree-id\n" }
    end,
  })
  rex = {
    action = function(action) actions[action.name] = action end,
    bind = function() end,
    call = function(method, args)
      calls[#calls + 1] = { method = method, args = args }
      return remote_result, remote_error
    end,
    block = { call = function()
      return { foreground = { cwd = remote and foreign_cwd or "/tmp/project" } }
    end },
    exec = exec,
    ui = { pick = function(opts)
      picks[#picks + 1] = opts
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

local function run()
  return actions.workspace_picker_native.run(ctx)
end

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL: " .. name .. ": " .. tostring(err) .. "\n")
    os.exit(1)
  end
  print("PASS: " .. name)
end

test("remote picker never executes a helper against the Mac filesystem", function()
  setup(true)
  assert(run() == remote_result)
  assert(#commands == 0 and #picks == 0 and layer == nil)
  assert(#calls == 1 and calls[1].method == "client.action")
  local request = calls[1].args
  assert(request.action == "workspace_picker_native")
  assert(request.session_id == ctx.session_id and request.block_id == ctx.block_id)
  assert(request.server == nil, "forwarded action must execute locally on the destination")
end)

test("remote failure is reported without falling back to local execution", function()
  setup(true)
  remote_result, remote_error = nil, "Remote configuration needs reloading"
  local ok, err = pcall(run)
  assert(not ok and err == remote_error)
  assert(#commands == 0)
end)

test("local picker lists worktrees and workplace directories and permits cancellation", function()
  setup(false)
  run()
  assert(#calls == 0 and #picks == 1 and layer == nil)
  assert(picks[1].items[1].id == "none")
  assert(picks[1].items[2].id == "tree-id")
  assert(picks[1].items[3].id == "/tmp/project")
end)

test("opening a directory keeps the helper on the pane's host", function()
  setup(false)
  selection, menu_action = "/tmp/project", "connect"
  run()
  local command = commands[#commands].argv
  assert(command[3] == "connect" and command[4] == "/tmp/project")
  assert(layer == nil)
end)

test("creating a worktree refocuses using the host's rex executable", function()
  setup(false)
  selection = "none"
  run()
  assert(layer.session_id == ctx.session_id)
  assert(layer.layout.options.cwd == "/tmp/project")
  assert(layer.layout.options.command[3] == "create")
  assert(#starts == 1 and starts[1].argv[4] == "rex")
  assert(starts[1].opts.env.PATH:find("/usr/bin", 1, true))
  assert(starts[1].opts.detach)
end)
