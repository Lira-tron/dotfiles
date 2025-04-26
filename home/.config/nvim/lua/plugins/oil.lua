return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  lazy = false,
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      columns = { "icon" },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-k>"] = false,
        ["<C-j>"] = false,
        ["<M-h>"] = "actions.select_split",
      },
      view_options = {
        show_hidden = true,
      },
    })
    -- Open parent directory in current window
    vim.keymap.set("n", "<space>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })

    -- Open parent directory in floating window
    -- vim.keymap.set("n", "<space>-", require("oil").toggle_float)
  end,
}
