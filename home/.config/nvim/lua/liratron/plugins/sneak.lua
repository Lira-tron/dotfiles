return {
    'justinmk/vim-sneak',
    init = function()
        vim.api.nvim_set_var('sneak#label', 1)
    end,
    keys = {
        { 's', '<Plug>Sneak_s' },
        { 'S', '<Plug>Sneak_S' },
        { 'f', '<Plug>Sneak_f' },
        { 'F', '<Plug>Sneak_F' },
        { 't', '<Plug>Sneak_t' },
        { 'T', '<Plug>Sneak_T' },
    },

}
