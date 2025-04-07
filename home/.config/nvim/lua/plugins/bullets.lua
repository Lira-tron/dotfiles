return {
  "bullets-vim/bullets.vim",
  config = function()
    -- Disable deleting the last empty bullet when pressing <cr> or 'o'
    -- default = 1
    vim.g.bullets_delete_last_bullet_if_empty = 1

    -- (Optional) Add other configurations here
    -- For example, enabling/disabling mappings
    -- vim.g.bullets_set_mappings = 1
  end,
}
