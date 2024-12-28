return {
  {
    -- "jnurmine/Zenburn",
    -- "sainnhe/gruvbox-material",
    -- "eddyekofo94/gruvbox-flat.nvim"
    "Lira-tron/concoctis.nvim",
    -- "sainnhe/everforest",
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local function setEverestForest()
        vim.g.everforest_background = "hard"
        if not vim.g.neovide then
          vim.g.everforest_transparent_background = 2
        end
        vim.g.everforest_better_performance = 1
        vim.g.everforest_enable_italic = true
        vim.g.everforest_cursor = "purple"
        vim.cmd.colorscheme("everforest")
      end

      local function setGruvboxMaterial()
        if not vim.g.neovide then
          vim.g.gruvbox_material_transparent_background = 2
        end
        vim.g.gruvbox_material_better_performance = 1
        vim.g.gruvbox_material_enable_italic = true
        vim.g.gruvbox_material_cursor = "purple"
        -- vim.g.gruvbox_material_background = 'dark'
        vim.cmd.colorscheme("gruvbox-material")
      end

      local function setConcoctis()
        require("concoctis").setup({
          -- override_highlights = {
          --   CursorLine = { bg = "#434443" },
          -- },
          transparent = true,
        })

        -- vim.api.nvim_create_autocmd("User", {
        --   pattern = "TelescopeFindPre",
        --   callback = function(args)
        --     vim.api.nvim_set_hl(0, "CursorLine", { bg = nil })
        --   end,
        -- })

        -- load the colorscheme here
        vim.cmd.colorscheme("concoctis")
      end
      setConcoctis()
    end,
  },
}
