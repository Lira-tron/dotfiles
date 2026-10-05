local M = {}

-- Deliberately kept in memory: each repository starts with the default scope
-- in every new Neovim process.
local scopes, buffers = {}, {}

local function git(cwd, args, callback)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, args)
  vim.system(command, { text = true }, vim.schedule_wrap(callback))
end

local function buffer_directory(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  path = vim.uv.fs_realpath(path) or path
  return vim.fn.fnamemodify(path, ":h"), vim.fn.fnamemodify(path, ":t")
end

local function refresh(buf)
  if not buffers[buf] or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local diff = require("mini.diff")
  local cwd, filename = buffer_directory(buf)
  local request = { root = buffers[buf].root }
  buffers[buf] = request

  local function run(args, callback)
    git(cwd, args, function(result)
      if buffers[buf] == request and vim.api.nvim_buf_is_valid(buf) then
        callback(result)
      end
    end)
  end

  local function read_reference(ref, label)
    local function set_text(text)
      vim.b[buf].minidiff_base_label = label
      diff.set_ref_text(buf, text)
    end
    if ref == "" then
      set_text("")
      return
    end
    local args = ref == ":index"
        and {
          "--literal-pathspecs",
          "ls-files",
          "--stage",
          "-z",
          "--",
          filename,
        }
      or {
        "--literal-pathspecs",
        "ls-tree",
        "--format=%(objectname)",
        ref,
        "--",
        filename,
      }
    run(args, function(tree)
      if tree.code ~= 0 then
        diff.disable(buf)
        return
      end
      local blob = vim.trim(tree.stdout)
      if ref == ":index" and blob ~= "" then
        local stage
        blob, stage = tree.stdout:match("^%d+ (%x+) (%d+)\t")
        if stage ~= "0" then
          diff.disable(buf)
          vim.notify(
            "No diff baseline: file has merge conflicts",
            vim.log.levels.WARN
          )
          return
        end
      end
      if blob == "" then
        -- A file absent from the reference is entirely new.
        set_text("")
        return
      end
      run({ "show", blob }, function(content)
        if content.code ~= 0 then
          diff.disable(buf)
          return
        end
        set_text(content.stdout)
      end)
    end)
  end

  run({ "check-ignore", "--quiet", "--", filename }, function(ignored)
    if ignored.code ~= 1 then
      diff.disable(buf)
      return
    end
    run({ "rev-parse", "--show-toplevel" }, function(repo)
      if repo.code ~= 0 then
        diff.disable(buf)
        return
      end
      request.root = vim.trim(repo.stdout)
      local scope = scopes[request.root]
      if scope then
        read_reference(scope.ref, "Custom: " .. scope.label)
        return
      end
      run({ "merge-base", "HEAD", "@{upstream}" }, function(base)
        local ref = base.code == 0 and vim.trim(base.stdout) or "HEAD"
        read_reference(ref, "Default: " .. ref:sub(1, 8))
      end)
    end)
  end)
end

local function open_picker(root, base, default_count, history)
  local items = {
    { text = "Default — upstream common ancestor", default = true },
    {
      text = "Unstaged changes, including unsaved edits",
      depth = 1,
      scope = { ref = ":index", label = "index" },
    },
    {
      text = "Staged changes",
      depth = 2,
      scope = { ref = "HEAD", label = "HEAD" },
    },
  }
  for line in history:gmatch("[^\n]+") do
    local commit, parents, subject = line:match("^(%x+)\t([^\t]*)\t(.*)$")
    local parent = parents:match("^%x+") or ""
    items[#items + 1] = {
      text = commit:sub(1, 8) .. "  " .. subject,
      commit = commit,
      depth = #items,
      scope = {
        ref = parent,
        label = parent == "" and "empty tree" or parent:sub(1, 8),
      },
    }
  end

  local pending = scopes[root]
  local depth = default_count + 2
  if pending then
    depth = #items - 1
    for _, item in ipairs(items) do
      if item.scope and item.scope.ref == pending.ref then
        depth = item.depth
        break
      end
    end
  end

  local function update(picker)
    local label = pending and ("Custom: " .. pending.label)
      or ("Default: " .. base:sub(1, 8))
    picker.title = "Diff scope · "
      .. vim.fn.fnamemodify(root, ":t")
      .. " · "
      .. label
    picker:update_titles()
    picker.list:update({ force = true })
  end

  local function restore_default(picker)
    pending, depth = nil, default_count + 2
    update(picker)
  end

  local keys = {
    ["<Space>"] = { "scope_select", mode = "n", desc = "Adjust range" },
    ["<Tab>"] = { "scope_select", mode = { "n", "i" } },
    ["<S-Tab>"] = { "scope_select", mode = { "n", "i" } },
    ["r"] = { "scope_default", mode = "n", desc = "Restore default" },
    ["<C-r>"] = { "scope_default", mode = "i" },
    ["<C-a>"] = false,
    ["<Esc>"] = { "close", mode = { "n", "i" } },
  }
  Snacks.picker({
    items = items,
    focus = "list",
    main = { current = true },
    format = function(item)
      local selected = item.default and pending == nil
        or (item.depth ~= nil and item.depth <= depth)
      local ref = pending and pending.ref or base
      local suffix = item.commit == ref and "  ← base" or ""
      return {
        { selected and "✓ " or "  ", "DiagnosticOk" },
        { item.text },
        { suffix, "Comment" },
      }
    end,
    layout = {
      preset = "select",
      layout = {
        width = 0.8,
        height = 0.6,
        footer = " Space: range   r: Default   Enter: apply   Esc: cancel ",
      },
    },
    win = { input = { keys = keys }, list = { keys = keys } },
    on_show = function(picker)
      vim.cmd.stopinsert()
      update(picker)
    end,
    actions = {
      scope_default = restore_default,
      scope_select = function(picker)
        local item = picker:current()
        if not item then
          return
        end
        if item.default then
          restore_default(picker)
          return
        end
        depth = item.depth <= depth and math.max(1, item.depth - 1)
          or item.depth
        pending = items[depth + 1].scope
        update(picker)
      end,
    },
    confirm = function(picker)
      scopes[root] = pending
      picker:close()
      for buf, request in pairs(buffers) do
        if request.root == root then
          refresh(buf)
        end
      end
    end,
  })
end

local function with_repository(callback)
  local original = vim.b.minidiff_original
  local buf = original and original.buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local cwd
  if vim.bo[buf].filetype == "oil" then
    cwd = require("oil").get_current_dir(buf)
  else
    cwd = buffer_directory(buf)
  end
  if not cwd then
    vim.notify("No local directory for this buffer", vim.log.levels.WARN)
    return
  end
  git(cwd, { "rev-parse", "--show-toplevel" }, function(repo)
    if repo.code ~= 0 then
      vim.notify("No Git repository for this buffer", vim.log.levels.WARN)
      return
    end
    callback(vim.trim(repo.stdout))
  end)
end

function M.pick()
  with_repository(function(root)
    git(root, { "merge-base", "HEAD", "@{upstream}" }, function(ancestor)
      local base = ancestor.code == 0 and vim.trim(ancestor.stdout) or "HEAD"
      git(
        root,
        { "rev-list", "--count", "--first-parent", base .. "..HEAD" },
        function(count)
          git(root, {
            "log",
            "--no-color",
            "--no-show-signature",
            "--first-parent",
            "--format=%H%x09%P%x09%s",
          }, function(history)
            if history.code ~= 0 then
              vim.notify(
                "Cannot read Git history: " .. vim.trim(history.stderr),
                vim.log.levels.WARN
              )
              return
            end
            open_picker(root, base, tonumber(count.stdout) or 0, history.stdout)
          end)
        end
      )
    end)
  end)
end

function M.git_diff(group)
  with_repository(function(root)
    local function open(ref, label)
      local args = {
        "--no-pager",
        "-c",
        "core.quotepath=false",
        "diff",
        "--no-color",
        "--no-ext-diff",
        "--diff-filter=u",
      }
      if ref ~= ":index" then
        args[#args + 1] = ref
      end
      args[#args + 1] = "--"
      -- Use the exact reference: Snacks' Git finder always adds --merge-base
      -- and otherwise combines separate staged and unstaged comparisons.
      Snacks.picker({
        title = "Git Diff ("
          .. (group and "files" or "hunks")
          .. ") · "
          .. label,
        finder = "diff",
        cmd = "git",
        args = args,
        cwd = root,
        group = group,
        format = "git_status",
        preview = "diff",
        matcher = { sort_empty = true },
        sort = { fields = { "score:desc", "file", "idx" } },
        main = { current = true },
      })
    end
    local scope = scopes[root]
    if not scope then
      git(root, { "merge-base", "HEAD", "@{upstream}" }, function(base)
        local ref = base.code == 0 and vim.trim(base.stdout) or "HEAD"
        open(ref, "Default: " .. ref:sub(1, 8))
      end)
    elseif scope.ref == "" then
      git(root, { "hash-object", "-t", "tree", "--stdin" }, function(tree)
        if tree.code ~= 0 then
          vim.notify("Cannot resolve empty-tree baseline", vim.log.levels.WARN)
          return
        end
        open(vim.trim(tree.stdout), "Custom: " .. scope.label)
      end)
    else
      open(scope.ref, "Custom: " .. scope.label)
    end
  end)
end

function M.source()
  local group = vim.api.nvim_create_augroup("MiniDiffScope", { clear = true })
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "FileChangedShellPost" },
    {
      group = group,
      callback = function(event)
        refresh(event.buf)
      end,
    }
  )
  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = group,
    callback = function()
      for buf in pairs(buffers) do
        refresh(buf)
      end
    end,
  })
  return {
    name = "git_scope",
    attach = function(buf)
      if vim.fn.executable("git") == 0 then
        return false
      end
      buffers[buf] = {}
      refresh(buf)
    end,
    detach = function(buf)
      buffers[buf] = nil
    end,
  }
end

return M
