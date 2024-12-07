return {
  "ellisonleao/glow.nvim",
  event = { "BufReadPre", "BufNewFile" },
  ft = { "markdown" },
  keys = {
    { "<leader>mg", "<cmd>Glow<CR>", { desc = "Mardown preview" } },
  },
  config = true,
  cmd = "Glow",
}
