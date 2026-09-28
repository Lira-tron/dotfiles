local function toggle_upstream(vertical)
  local original = vim.b.minidiff_original
  if original then
    if original.vertical then
      vim.api.nvim_win_close(0, true)
      return
    end
    if not vim.api.nvim_buf_is_valid(original.buf) then
      vim.notify("Original buffer is no longer available", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_win_set_buf(0, original.buf)
    vim.fn.winrestview(original.view)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local data = require("mini.diff").get_buf_data(buf)
  if not data or data.ref_text == nil then
    vim.notify(
      "No diff baseline available for this buffer",
      vim.log.levels.WARN
    )
    return
  end

  local view = vim.fn.winsaveview()
  local preview = vim.api.nvim_create_buf(false, true)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  vim.api.nvim_buf_set_name(
    preview,
    "upstream://" .. preview .. "/" .. filename
  )
  vim.api.nvim_buf_set_lines(
    preview,
    0,
    -1,
    false,
    vim.split(data.ref_text:gsub("\n$", ""), "\n", { plain = true })
  )
  vim.b[preview].minidiff_original =
    { buf = buf, view = view, vertical = vertical }
  vim.bo[preview].bufhidden = "wipe"
  vim.bo[preview].filetype = vim.bo[buf].filetype
  vim.bo[preview].modified = false
  vim.bo[preview].modifiable = false
  vim.bo[preview].readonly = true
  vim.keymap.set("n", "q", "<leader>gU", {
    buffer = preview,
    remap = true,
    desc = "Close Upstream Baseline",
  })
  if vertical then
    vim.cmd.vsplit()
  end
  vim.api.nvim_win_set_buf(0, preview)
  vim.fn.winrestview(view)
end

return {
  "nvim-mini/mini.diff",
  keys = {
    {
      "<leader>gu",
      function()
        toggle_upstream(true)
      end,
      desc = "Upstream Baseline File (Vertical Split)",
    },
    {
      "<leader>gU",
      function()
        toggle_upstream(false)
      end,
      desc = "Toggle Upstream Baseline File",
    },
    {
      "<leader>gn",
      function()
        require("mini.diff").goto_hunk("next")
      end,
      desc = "Next Diff Hunk",
    },
    {
      "<leader>gp",
      function()
        require("mini.diff").goto_hunk("prev")
      end,
      desc = "Previous Diff Hunk",
    },
    { "gng", "<leader>gn", remap = true, desc = "Next Diff Hunk" },
    { "gpg", "<leader>gp", remap = true, desc = "Previous Diff Hunk" },
  },
  opts = function(_, opts)
    local diff = require("mini.diff")
    local requests = {}

    local function refresh(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local path = vim.api.nvim_buf_get_name(buf)
      path = vim.uv.fs_realpath(path) or path
      local cwd = vim.fn.fnamemodify(path, ":h")
      local filename = vim.fn.fnamemodify(path, ":t")
      local request = {}
      requests[buf] = request

      local function git(args, callback)
        local command = { "git", "-C", cwd }
        vim.list_extend(command, args)
        vim.system(
          command,
          { text = true },
          vim.schedule_wrap(function(result)
            if requests[buf] == request and vim.api.nvim_buf_is_valid(buf) then
              callback(result)
            end
          end)
        )
      end

      local function read_reference(ref)
        git(
          { "ls-tree", "--format=%(objectname)", ref, "--", filename },
          function(tree)
            if tree.code ~= 0 then
              diff.disable(buf)
              return
            end
            local blob = vim.trim(tree.stdout)
            if blob == "" then
              -- Files added since the reference are entirely new.
              diff.set_ref_text(buf, "")
              return
            end
            git({ "show", blob }, function(content)
              if content.code ~= 0 then
                diff.disable(buf)
                return
              end
              diff.set_ref_text(buf, content.stdout)
            end)
          end
        )
      end

      git({ "check-ignore", "--quiet", "--", filename }, function(ignored)
        if ignored.code ~= 1 then
          diff.disable(buf)
          return
        end
        git({ "merge-base", "HEAD", "@{upstream}" }, function(base)
          -- The common ancestor excludes incoming upstream-only changes.
          read_reference(base.code == 0 and vim.trim(base.stdout) or "HEAD")
        end)
      end)
    end

    opts.source = {
      name = "git_upstream",
      attach = function(buf)
        if vim.fn.executable("git") == 0 then
          return false
        end
        refresh(buf)
      end,
      detach = function(buf)
        requests[buf] = nil
      end,
    }
    -- These hunks include commits: keep staging/resetting in the Git client.
    opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
      apply = "",
      reset = "",
    })

    local group =
      vim.api.nvim_create_augroup("MiniDiffUpstream", { clear = true })
    vim.api.nvim_create_autocmd(
      { "BufEnter", "BufWritePost", "FileChangedShellPost" },
      {
        group = group,
        callback = function(event)
          if requests[event.buf] then
            refresh(event.buf)
          end
        end,
      }
    )
    vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
      group = group,
      callback = function()
        for buf in pairs(requests) do
          refresh(buf)
        end
      end,
    })
  end,
}
