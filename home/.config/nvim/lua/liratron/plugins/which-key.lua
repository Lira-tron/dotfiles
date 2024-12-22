return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")
    wk.add({
      {
        mode = { "n", "v" },
        { "<leader>d", group = "Debug" },
        { "<leader>g", group = "Git" },
        { "<leader>m", group = "Markdown/Harpoon" },
        { "<leader>p", group = "Project" },
        { "<leader>r", group = "Refactor" },
        { "<leader>s", group = "Search" },
        { "<leader>t", group = "Terminal" },
        { "<leader>w", group = "Wiki" },
        { "<leader>X", group = "Reload" },
        { "<leader>z", group = "Focus" },
        { "<leader>sg", group = "Git" },
        { "gp", group = "Prev/Peek" },
        { "gn", group = "Next" },
        { "gh", group = "Hierarchy" },
        { "gl", group = "Line/Gen AI" },
        { "gc", group = "Comment/Code" },
      },
    })
  end,
}
