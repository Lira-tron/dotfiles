return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    keys = {
      { "<leader>wbs", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Browser Preview Toggle" },
      { "<leader>wbx", "<cmd>MarkdownPreviewStop<CR>", desc = "Markdown Browser Preview Stop" },
    },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    "ellisonleao/glow.nvim",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "markdown" },
    keys = {
      { "<leader>wg", "<cmd>Glow<CR>", { desc = "[M]ardown [D]isplay Glow" } },
    },
    config = true,
    cmd = "Glow",
  },
}
