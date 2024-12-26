return {
  {
    -- "jnurmine/Zenburn",
    -- "sainnhe/gruvbox-material",
    -- "eddyekofo94/gruvbox-flat.nvim"
    -- "GwHisHere/concoctis.nvim",
    "sainnhe/everforest",
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local function setEverestForest()
        -- Optionally configure and load the colorscheme
        -- directly inside the plugin declaration.
        vim.g.everforest_background = "hard"
        if not vim.g.neovide then
          vim.g.everforest_transparent_background = 2
        end
        vim.g.everforest_better_performance = 1
        vim.g.everforest_enable_italic = true
        vim.cmd.colorscheme("everforest")
      end

      local function setConcoctis()
        require("concoctis").setup({
          transparent = true,
        })
        -- load the colorscheme here
        vim.cmd.colorscheme("concoctis")
      end
      setEverestForest()
    end,
  },
}
