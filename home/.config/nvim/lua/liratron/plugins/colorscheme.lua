return {
  {
    -- "jnurmine/Zenburn",
    -- "sainnhe/gruvbox-material",
    -- "eddyekofo94/gruvbox-flat.nvim"
    "GwHisHere/concoctis.nvim",

    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("concoctis").setup({
        transparent = true,
      })
      -- load the colorscheme here
      vim.cmd([[colorscheme concoctis]])
    end,
  },
}
