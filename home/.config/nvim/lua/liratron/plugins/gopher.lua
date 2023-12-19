return {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = true,
    build = function()
        vim.cmd [[silent! GoInstallDeps]]
    end,
}
