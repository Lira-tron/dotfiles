-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.notesdir = os.getenv( "HOME" ) .. "/workplace/LimonoctNvim/src/LimonoctNvim/notes/journal"
-- timeout = true means Neovim will wait for potential mapping completions
-- timeoutlen = 1000 gives you 1 second to complete a key mapping sequence
-- Note: This is just the maximum wait time - if you type the complete mapping
-- faster (e.g., <leader>ff in 200ms), it executes immediately without waiting
-- for the full 1000ms. LazyVim defaults to 300ms, but I will test the more
-- relaxed default of 1000ms here.
vim.opt.timeout = true
-- Default neovim is 1,000 but lazyvim sets it to 300
vim.opt.timeoutlen = 1000

vim.g.snacks_animate = false
vim.opt.relativenumber = true
vim.opt.textwidth = 80

-- -- Disable line wrap, set to false by default in lazyvim
vim.opt.wrap = true

-- Shows colorcolumn that helps me with markdown guidelines.
-- This is the vertical bar that shows the 80 character limit
-- This applies to ALL file types
vim.opt.colorcolumn = "80"

vim.opt.cursorcolumn = true

-- I mainly type in english, if I set it to both above, files in English get a
-- bit confused and recognize words in spanish, just for spanish files I need to
-- set it to both
vim.opt.spelllang = { "en" }

-- Show LSP diagnostics (inlay hints) in a hover window / popup
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#show-line-diagnostics-automatically-in-hover-window
-- https://www.reddit.com/r/neovim/comments/1168p97/how_can_i_make_lspconfig_wrap_around_these_hints/
-- Time it takes to show the popup after you hover over the line with an error
vim.o.updatetime = 200

vim.g.autoformat = false

if vim.g.neovide then
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode

  -- This allows me to use cmd+v to paste stuff into neovide
  vim.api.nvim_set_keymap(
    "",
    "<D-v>",
    "+p<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap(
    "!",
    "<D-v>",
    "<C-R>+",
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap(
    "t",
    "<D-v>",
    "<C-R>+",
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap(
    "v",
    "<D-v>",
    "<C-R>+",
    { noremap = true, silent = true }
  )

  -- NOTE: vsync is configured in the neovide/config.toml file, I disabled it and set
  -- this to 120 even though my monitor is 75Hz, had a similar case in wezterm,
  -- see: https://github.com/wez/wezterm/issues/6334
  vim.g.neovide_refresh_rate = 120
  -- This is how fast the cursor animation "moves", default 0.06
  vim.g.neovide_cursor_animation_length = 0.04
  -- Default 0.7
  vim.g.neovide_cursor_trail_size = 0.7

  -- produce particles behind the cursor, if want to disable them, set it to ""
  -- vim.g.neovide_cursor_vfx_mode = "railgun"
  -- vim.g.neovide_cursor_vfx_mode = "torpedo"
  -- vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_vfx_mode = "sonicboom"
  -- vim.g.neovide_cursor_vfx_mode = "ripple"
  -- vim.g.neovide_cursor_vfx_mode = "wireframe"

  -- Really weird issue in which my winbar would be drawn multiple times as I
  -- scrolled down the file, this fixed it, found in:
  -- https://github.com/neovide/neovide/issues/1550
  vim.g.neovide_scroll_animation_length = 0
  vim.g.neovide_transparency = 0.9

  vim.g.neovide_padding_top = 15
  vim.g.neovide_padding_bottom = 5
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
end
