--vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2 -- set number column width to 2 {default 4}

vim.opt.cmdheight = 0 -- more space in the neovim command line for displaying messages
vim.opt.tabstop = 4 -- insert 2 spaces for a tab
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4 -- the number of spaces inserted for each indentation
vim.opt.expandtab = true -- convert tabs to spaces

vim.opt.smartindent = true -- make indenting smarter again

vim.opt.wrap = true -- display lines as one long line
vim.opt.linebreak = true -- companion to wrap, don't split words

vim.opt.swapfile = false -- creates swap file
vim.opt.backup = false -- creates a backup file
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true -- enable persistent undo

vim.opt.hlsearch = false -- highlight all matches on previous search pattern
vim.opt.incsearch = true

vim.opt.mouse = "a" -- allow the mouse to be used in neovim

vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.smartcase = true -- smart case

vim.wo.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time

vim.opt.completeopt = "menuone,noselect" -- mostly just for cmp

-- Enable break indent
vim.opt.breakindent = true

-- Decrease update tim:
vim.opt.updatetime = 250 -- faster completion (4000ms default)
vim.opt.timeoutlen = 300 -- time to wait for a mapped sequence to complete (in milliseconds)

vim.opt.termguicolors = true -- set term gui colors (most terminals support this)

vim.opt.scrolloff = 8 -- minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 8 -- minimal number of screen columns either side of cursor if wrap is `false`

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.cursorline = true -- highlight the current line
vim.opt.cursorcolumn = true -- highlight the current column

-- vim.opt.guifont = "monospace:h17"               -- the font used in graphical neovim applications
if vim.fn.has("unix") == 1 then
  local uname = vim.fn.system("uname")
  if uname == "Darwin\n" then
    vim.opt.guifont = "JetBrains Mono:h15"
  elseif vim.g.neovide then
    vim.opt.guifont = "JetBrains Mono:h15"
  else
    vim.opt.guifont = "JetBrains Mono 15"
  end
end

vim.opt.textwidth = 100 -- When text reaches this limit, it automatically wraps to the next line..

vim.g.disable_autoformat = true

--Fold
vim.opt.foldcolumn = "0"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldtext = ""

vim.opt.foldnestmax = 3
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.g.notesdir = "/Users/lira/Documents/Notes"

if vim.g.neovide then
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode

  -- This allows me to use cmd+v to paste stuff into neovide
  vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

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

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH
