return {
  'ojroques/vim-oscyank',
  init = function()
    vim.g.oscyank_term = 'default'
    vim.g.oscyank_silent = true
  end,
  config = function()
    vim.keymap.set({ 'v', 'x' }, '<leader>y', ':OSCYankVisual<CR>', { silent = true, desc = 'OSC yank' })
    vim.keymap.set({ 'n' }, '<leader>y', '<Plug>OSCYank', { silent = true, desc = 'OSC yank' })
  end
}
