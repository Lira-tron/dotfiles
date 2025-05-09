return {
  'ojroques/vim-oscyank',
  init = function()
    vim.g.oscyank_term = 'default'
    vim.g.oscyank_silent = true
    vim.g.oscyank_max_length = 0
  end,
  config = function()
    -- Below autocmd is for copying to OSC52 for any yank operation,
    -- see https://github.com/ojroques/vim-oscyank#copying-from-a-register
    vim.api.nvim_create_autocmd("TextYankPost", {
      pattern = "*",
      callback = function()
        if vim.v.event.operator == "y" and vim.v.event.regname == "" then
          vim.cmd('OSCYankRegister "')
        end
      end,
    })
    -- vim.keymap.set({ 'v', 'x' }, '<leader>y', ':OSCYankVisual<CR>', { silent = true, desc = 'OSC yank' })
    -- vim.keymap.set({ 'n' }, '<leader>y', '<Plug>OSCYank', { silent = true, desc = 'OSC yank' })
  end
}
