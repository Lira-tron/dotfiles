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
        { "<leader>m", group = "Harpoon" },
        { "<leader>p", group = "Project" },
        { "<leader>r", group = "Refactor" },
        { "<leader>s", group = "Search" },
        { "<leader>t", group = "Terminal" },
        { "<leader>X", group = "Reload" },
        { "<leader>z", group = "Focus" },
        { "<leader>sg", group = "Git" },
        { "<leader>w", group = "Markdown" },
        { "<leader>wb", group = "Markdown Browser" },
        { "<leader>wf", group = "Fold" },
        { "<leader>wh", group = "Headings increase/decrease" },
        { "<leader>wl", group = "Links" },
        { "<leader>ws", group = "Spell" },
        { "<leader>wsl", group = "Language" },
        { "gp", group = "Prev/Peek" },
        { "gn", group = "Next" },
        { "gh", group = "Hierarchy" },
        { "gl", group = "Line/Gen AI" },
        { "gc", group = "Comment/Code" },
        { "gsm", group = "Custom surround" },
        { "gs", group = "Surround" },
      },
    })
  end,
}
