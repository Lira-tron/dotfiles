return {
  "danymat/neogen",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("neogen").setup({})
    local opts = {
      silent = true,
      noremap = true,
    }
    vim.api.nvim_set_keymap("n", "gjd", ":lua require('neogen').generate()<CR>", opts)
  end,
}
