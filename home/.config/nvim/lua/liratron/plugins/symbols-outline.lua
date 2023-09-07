return {
  "simrat39/symbols-outline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function ()
    require("symbols-outline").setup()
    vim.keymap.set("n", "<leader>po", "<cmd>SymbolsOutline<CR>", { desc = "[P]roject [O]utline symbols" })
  end
}
