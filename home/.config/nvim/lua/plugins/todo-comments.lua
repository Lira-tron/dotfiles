return {
  "folke/todo-comments.nvim",
  keys = {
    { "]t", false },
    { "[t", false },
    { "<leader>st", false },
    { "<leader>sT", false },
    {
      "gnT",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next Todo Comment",
    },
    {
      "gpT",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous Todo Comment",
    },

    {
      "<leader>stt",
      function()
        Snacks.picker.todo_comments()
      end,
      desc = "[T]odo",
    },
    {
      "<leader>stp",
      function()
        Snacks.picker.todo_comments({ cwd = vim.g.notesdir })
      end,
      desc = "[T]odo for [P]lanning",
    },
    {
      "<leader>sta",
      function()
        Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
      end,
      desc = "Todo/Fix/Fixme",
    },
    {
      "<leader>stl",
      function()
        vim.ui.input({ prompt = "Tag: #" }, function(tag)
          tag = tag and vim.trim(tag) or ""
          if tag ~= "" then
            Snacks.picker.grep({
              prompt = " ",
              search = "^\\s*- \\[ \\].*#" .. tag .. "\\w*",
              regex = true,
              live = false,
              dirs = { vim.g.notesdir },
              args = { "--no-ignore" },
              on_show = function()
                vim.cmd.stopinsert()
              end,
              finder = "grep",
              format = "file",
              show_empty = true,
              supports_live = false,
              layout = "ivy",
              transform = function(item)
                local stat = item.file and vim.uv.fs_stat(item.file)
                item.mtime = stat and stat.mtime.sec or 0
              end,
              sort = { fields = { "mtime:desc", "file", "lnum" } },
            })
          end
        end)
      end,
      desc = "Tasks by #[l]abel",
    },
    {
      "<leader>sth",
      function()
        local cmd = {
          "rg",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--no-ignore",
          "^\\s*- \\[ \\].*#\\w+",
          vim.g.notesdir,
        }
        local out = vim.fn.systemlist(cmd)
        local tags = {} ---@type table<string, { mtime: integer, file: string, lnum: integer, text: string }>
        for _, line in ipairs(out) do
          local file, lnum, text = line:match("^(.-):(%d+):(.*)$")
          if file then
            local stat = vim.uv.fs_stat(file)
            local mtime = stat and stat.mtime.sec or 0
            for tag in text:gmatch("#(%w+)") do
              local prev = tags[tag]
              if not prev or mtime > prev.mtime then
                tags[tag] = { mtime = mtime, file = file, lnum = tonumber(lnum), text = text }
              end
            end
          end
        end
        local items = {}
        for tag, info in pairs(tags) do
          items[#items + 1] = {
            text = "#" .. tag .. "  " .. info.text,
            tag = tag,
            file = info.file,
            pos = { info.lnum, 0 },
            mtime = info.mtime,
          }
        end
        Snacks.picker.pick({
          source = "tasks_by_tag",
          items = items,
          format = "text",
          layout = "ivy",
          sort = { fields = { "mtime:desc" } },
          confirm = function(picker, item)
            picker:close()
            if not item then
              return
            end
            Snacks.picker.grep({
              prompt = " ",
              search = "^\\s*- \\[ \\].*#" .. item.tag .. "\\b",
              regex = true,
              live = false,
              dirs = { vim.g.notesdir },
              args = { "--no-ignore" },
              on_show = function()
                vim.cmd.stopinsert()
              end,
              finder = "grep",
              format = "file",
              show_empty = true,
              supports_live = false,
              layout = "ivy",
            })
          end,
        })
      end,
      desc = "Tasks tags by date ([h]istory)",
    },

    -- { "<leader>stt", "<cmd>TodoTelescope keywords=TODO<cr>", desc = "[T]odo" },
    -- {
    --   "<leader>stp",
    --   "<cmd>TodoTelescope cwd=" .. vim.g.notesdir .. " keywords=TODO<cr>",
    --   desc = "[T]odo for [P]lanning",
    -- },
    -- { "<leader>sta", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
  },
}
