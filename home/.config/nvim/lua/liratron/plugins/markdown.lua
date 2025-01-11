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
    init = function()
      local palette = require("concoctis.palette").get_palette()
      vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = palette.bg2 })
      -- The 'highlight_inline' attribute for the 'code' block defaults to 'RenderMarkdownCode'.
      -- If setting 'fg = gruvbox_bright_green' for 'RenderMarkdownCode', everything inside a code block gets
      -- highlighted bright_green. If using the default value for 'highlight_inline', inline code in headings
      -- become black boxes. To fix this, define a new highlight group and assign it to 'highlight_inline'.
      vim.api.nvim_set_hl(0, "_InlineCode", { fg = palette.green, bg = palette.bg2 })
      -- stylua: ignore start #1d2021
      vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { fg = palette.bg0, bg = palette.darkGreen, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { fg = palette.bg0, bg = palette.darkBlue, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { fg = palette.bg0, bg = palette.darkAqua, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { fg = palette.bg0, bg = palette.darkPurple, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { fg = palette.bg0, bg = palette.darkYellow, bold = true })
      vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { fg = palette.bg0, bg = palette.darkRed, bold = true })
    end,
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
