return {
    "iamcco/markdown-preview.nvim",
    dependencies = { "zhaozg/vim-diagram", "aklt/plantuml-syntax" },
    event = "BufRead",
    build = function()
        vim.fn["mkdp#util#install"]()
    end,
}
