--vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2                      -- set number column width to 2 {default 4}

vim.opt.cmdheight = 0  -- more space in the neovim command line for displaying messages
vim.opt.tabstop = 4 -- insert 2 spaces for a tab
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4  -- the number of spaces inserted for each indentation
vim.opt.expandtab = true -- convert tabs to spaces

vim.opt.smartindent = true -- make indenting smarter again

vim.opt.wrap = true  -- display lines as one long line
vim.opt.linebreak = true  -- companion to wrap, don't split words


vim.opt.swapfile = false -- creates swap file
vim.opt.backup = false  -- creates a backup file
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true  -- enable persistent undo

vim.opt.hlsearch = false  -- highlight all matches on previous search pattern
vim.opt.incsearch = true

vim.opt.mouse = "a"  -- allow the mouse to be used in neovim

vim.opt.clipboard = "unnamedplus"  -- allows neovim to access the system clipboard

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true -- ignore case in search patterns
vim.opt.smartcase = true -- smart case

vim.wo.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time

vim.opt.completeopt = "menuone,noselect"  -- mostly just for cmp

-- Enable break indent
vim.opt.breakindent = true

-- Decrease update tim:
vim.opt.updatetime = 250 -- faster completion (4000ms default)
vim.opt.timeoutlen = 300 -- time to wait for a mapped sequence to complete (in milliseconds)

vim.opt.termguicolors = true -- set term gui colors (most terminals support this)

vim.opt.scrolloff = 8  -- minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 8                       -- minimal number of screen columns either side of cursor if wrap is `false`

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.colorcolumn = "100"

vim.opt.cursorline = true -- highlight the current line
vim.opt.cursorcolumn = true -- highlight the current column

vim.opt.guifont = "monospace:h17"               -- the font used in graphical neovim applications

vim.g.disable_autoformat = true

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH



