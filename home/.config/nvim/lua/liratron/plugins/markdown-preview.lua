return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  keys = {
    { "<leader>mpt", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview Toggle" } },
    { "<leader>mps", "<cmd>MarkdownPreviewStop<CR>", { desc = "Markdown Preview Stop" } },
  },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
}
