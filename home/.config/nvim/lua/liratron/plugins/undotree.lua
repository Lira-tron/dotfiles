return {
  -- file history
  'mbbill/undotree',
  vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "[U]ndoTree File history"})
}
