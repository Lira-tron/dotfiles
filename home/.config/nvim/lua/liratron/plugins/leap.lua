return {
    -- general-purpose motion plugin
    'ggandor/leap.nvim',
    config = function()
        vim.keymap.set('n', 's', '<Plug>(leap-forward-to)', { desc = 'Leap forward-to' })
        vim.keymap.set('n', 'S', '<Plug>(leap-backward-to)', { desc = 'Leap backward-to' })
    end
}
