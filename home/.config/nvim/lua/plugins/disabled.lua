local is_neovide = vim.g.neovide or false

return {

  -- This is the plugin that shows tabs, I don't need it as I use BufExplorer and snipe
  -- I enable the plugin only if the is_neovide variable is set to true
  { "akinsho/bufferline.nvim", enabled = is_neovide },
  -- { "Rics-Dev/project-explorer.nvim", enabled = is_neovide },

  -- Disable '3rd/image.nvim' if running Neovide, or you will get the error:
  -- Failed to run `config` for image.nvim
  -- .../lazy/image.nvim/lua/image/utils/term.lua:34: Failed to get terminal size
  {
    "3rd/image.nvim",
    cond = function()
      return not (vim.g.neovide == true)
    end,
  },
}
