return {
  "nvim-mini/mini.diff",
  keys = {
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
