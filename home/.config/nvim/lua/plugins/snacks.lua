return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      layout = {
        preset = "ivy",
        -- When reaching the bottom of the results in the picker, I don't want
        -- it to cycle and go back to the top
        cycle = false,
      },
      layouts = {
        ivy = {
          layout = {
            height = 0.8,
          },
        },
      },
      matcher = {
        frecency = true,
      },
    },
    lazygit = {
        theme = {
          selectedLineBgColor = { bg = "CursorLine" },
        },
        win = {
          width = 0,
          height = 0,
        },
      },
  },
  keys = {
    { "<leader>e", false },
    { "<leader>E", false },

    -- Open git log in vertical view
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log({
          finder = "git_log",
          format = "git_log",
          preview = "git_show",
          confirm = "git_checkout",
          layout = "vertical",
        })
      end,
      desc = "[G]it [L]og vertical view",
    },

    -- -- Iterate through incomplete tasks in Snacks_picker
    {
      "<leader>sti",
      function()
        Snacks.picker.grep({
          prompt = " ",
          -- pass your desired search as a static pattern
          search = "^\\s*- \\[ \\]",
          -- we enable regex so the pattern is interpreted as a regex
          regex = true,
          -- no “live grep” needed here since we have a fixed pattern
          live = false,
          -- restrict search to the current working directory
          dirs = { vim.g.notesdir },
          -- include files ignored by .gitignore
          args = { "--no-ignore" },
          -- Start in normal mode
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
      desc = "[S]earch for [T]asks [I]ncomplete",
    },
    -- -- Iterate throuth completed tasks in Snacks_picker lamw26wmal
    {
      "<leader>std",
      function()
        Snacks.picker.grep({
          prompt = " ",
          -- pass your desired search as a static pattern
          search = "^\\s*- \\[x\\] `done:",
          -- we enable regex so the pattern is interpreted as a regex
          regex = true,
          -- no “live grep” needed here since we have a fixed pattern
          live = false,
          -- restrict search to the current working directory
          dirs = { vim.g.notesdir },
          -- include files ignored by .gitignore
          args = { "--no-ignore" },
          -- Start in normal mode
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
      desc = "[S]earch for [T]asks [Done]",
    },
    {
      "<leader>stg",
      function()
        Snacks.picker.grep({
          prompt = " ",
          -- pass your desired search as a static pattern
          search = "TODO;",
          -- we enable regex so the pattern is interpreted as a regex
          regex = true,
          -- no “live grep” needed here since we have a fixed pattern
          live = false,
          -- restrict search to the current working directory
          dirs = { vim.g.notesdir },
          -- include files ignored by .gitignore
          args = { "--no-ignore" },
          -- Start in normal mode
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
      desc = "[S]earch for [T]ODOs [G]Completed in planning",
    },
    {
      "<leader>sp",
      function()
        Snacks.picker.spelling()
      end,
      desc = "[Search] for s[P]elling",
    },
  },
}
