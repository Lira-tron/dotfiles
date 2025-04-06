return {
  "ThePrimeagen/refactoring.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup()
    vim.api.nvim_set_keymap(
      "v",
      "<leader>ri",
      [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]],
      { noremap = true, silent = true, expr = false }
    )
    -- load refactoring Telescope extension
    require("telescope").load_extension("refactoring")

    vim.keymap.set({ "n", "v" }, "<leader>rr", function()
      require("telescope").extensions.refactoring.refactors()
    end)
  end,
}
