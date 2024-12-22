return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  keys = {
    { "<leader>mbs", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview Toggle" } },
    { "<leader>mbx", "<cmd>MarkdownPreviewStop<CR>", { desc = "Markdown Preview Stop" } },
  },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
}
