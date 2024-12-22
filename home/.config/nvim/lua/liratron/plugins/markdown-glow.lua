return {
  "ellisonleao/glow.nvim",
  event = { "BufReadPre", "BufNewFile" },
  ft = { "markdown" },
  keys = {
    { "<leader>md", "<cmd>Glow<CR>", { desc = "[M]ardown [D]isplay Glow" } },
  },
  config = true,
  cmd = "Glow",
}
