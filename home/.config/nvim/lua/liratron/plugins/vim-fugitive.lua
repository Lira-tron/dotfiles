return {
    'tpope/vim-fugitive',
    dependencies = {
        -- Git commit browser.
        {
            'junegunn/gv.vim',
            config = function()
                vim.keymap.set('n', '<Leader>gl', ':GV<CR>', { silent = true, desc = 'Git log tree' })
                vim.keymap.set('n', '<Leader>ga', ':GV --all<CR>', { silent = true, desc = 'Git log tree --all' })
            end
        },

        -- Enables :GBrowse from fugitive.vim to open GitHub URLs.
        {
            "tpope/vim-rhubarb",
        },
    },
    config = function()
        vim.keymap.set('n', '<Leader>gf', ':Git ', { desc = 'Git' })
        vim.keymap.set('n', '<Leader>gfs', ':Git<CR>', { silent = true, desc = 'Git status' })
        vim.keymap.set('n', '<Leader>gfp', ':Git push<CR>', { silent = true, desc = 'Git push' })
        vim.keymap.set({ 'n', 'v' }, '<Leader>go', ':GBrowse<CR>', { silent = true, desc = 'Git browse' })
        vim.keymap.set({ 'n', 'v' }, '<Leader>gc', ':GBrowse!<CR>', { silent = true, desc = 'Git browse' })
        vim.keymap.set('n', '<Leader>gb', ':Git blame<CR>', { silent = true, desc = 'Git blame' })
    end
}
