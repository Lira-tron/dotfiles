return {
  "folke/which-key.nvim",
  opts = {
    preset = "helix",
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>st", group = "TODOs/tasks" },
        { "gn", group = "Go next" },
        { "gp", group = "Go prev" },
        { "<leader>uW", group = "Spelling config" },
        { "<leader>m", group = "Markdown" },
      },
    },
  },
  -- config = function()
  --   require("which-key").setup({
  --     -- delay = 1500,
  --   })
  -- end,
}
