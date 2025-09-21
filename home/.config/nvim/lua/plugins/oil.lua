return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  lazy = false,
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
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
        ["q"] = { "actions.close", mode = "n" },
      },
      view_options = {
        show_hidden = true,
      },
    })
    -- Open parent directory in current window
    vim.keymap.set(
      "n",
      "<space>E",
      "<CMD>Oil<CR>",
      { desc = "Open file [E]xplorer directory" }
    )

    vim.keymap.set("n", "<leader>e", function()
      local oil = require("oil")
      local util = require("oil.util")
      -- oil.toggle_float()
      oil.open()
      util.run_after_load(0, function()
        oil.open_preview()
      end)
    end, { desc = "open file [E]xplorer with preview" })
  end,
}
