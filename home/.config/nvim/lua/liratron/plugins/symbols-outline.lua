return {
  "simrat39/symbols-outline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function ()
    require("symbols-outline").setup()
    vim.keymap.set("n", "go", "<cmd>SymbolsOutline<CR>", { desc = "Project [O]utline symbols" })
  end
}
