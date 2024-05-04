return {
    {
      "sainnhe/gruvbox-material",
      priority = 1000, -- make sure to load this before all the other start plugins
      config = function()
        -- load the colorscheme here
        vim.cmd([[colorscheme gruvbox-material]])
      end,
    },
    -- {
    --     'rose-pine/neovim',
    --     priority = 1000,
    --     config = function()
    --         vim.cmd('colorscheme rose-pine')
    --         require('rose-pine').setup({
    --             disable_background = true
    --         })
    --
    --         function ColorMyPencils(color)
    --             color = color or "rose-pine"
    --             vim.cmd.colorscheme(color)
    --
    --             vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    --             vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    --         end
    --
    --         ColorMyPencils()
    --     end,
    -- },
}

