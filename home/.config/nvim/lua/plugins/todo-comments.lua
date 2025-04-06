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
    -- { "<leader>stt", "<cmd>TodoTelescope keywords=TODO<cr>", desc = "[T]odo" },
    -- {
    --   "<leader>stp",
    --   "<cmd>TodoTelescope cwd=" .. vim.g.notesdir .. " keywords=TODO<cr>",
    --   desc = "[T]odo for [P]lanning",
    -- },
    -- { "<leader>sta", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
  },
}
