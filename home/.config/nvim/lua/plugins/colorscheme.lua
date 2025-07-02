return {
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanso").setup({
        transparent = not vim.g.neovide,
        theme = "ink", -- Load "zen" theme
        background = { -- map the value of 'background' option to a theme
          dark = "ink", -- try "ink" !
          light = "pearl",
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
  {
    "sainnhe/sonokai",
    lazy = true,
    config = function()
      -- vim.g.sonokai_style = "shusia"
      vim.g.sonokai_enable_italic = true
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    config = function()
      if not vim.g.neovide then
        vim.g.gruvbox_material_transparent_background = 2
      end
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_cursor = "purple"
    end,
  },
  {
    "sainnhe/everforest",
    lazy = true,
    config = function()
      vim.g.everforest_background = "hard"
      if not vim.g.neovide then
        vim.g.everforest_transparent_background = 2
      end
      vim.g.everforest_better_performance = 1
      vim.g.everforest_enable_italic = true
      vim.g.everforest_cursor = "purple"
    end,
  },
  {
    "jnurmine/Zenburn",
    lazy = true,
    config = true,
  },

  {
    "Lira-tron/concoctis.nvim",
    lazy = true,
    config = function()
      require("concoctis").setup({
        override_highlights = {
          -- NoiceCmdlinePopupBorder = { bg = "#434443" },
          -- NoicePopupBorder = { bg = "#434443" },
        },
        transparent = not vim.g.neovide,
      })
    end,
  },
}
