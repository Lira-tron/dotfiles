vim.g.mapleader = " "

--vim.keymap.set("n", "<leader>pv", vim.cmd.Ex,  { desc = '[P]roject [V]iew')

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "When highlighted move the line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "When highlighted move the line up" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Paste below line at the end of the line without moving cursor " })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "C-d keep cursor in middle" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "C-u keep cursor in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "search keep cursor in middle" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "search keep cursor in middle" })

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without having it in buffer" })

-- next greatest remap ever :
-- vim.keymap.set({ "n", "v" }, "y", [["+y]], { desc = "Copy to clipboard" } )
-- vim.keymap.set("n", "Y", [["+Y]], { desc = "Copy to clipboard" })

vim.keymap.set({ "n", "v" }, "<leader>D", [["_d]])

-- This is going to get me cancelledkeykeykeykey
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>ts", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "change to session" })
vim.keymap.set("n", "<leader>rf", vim.lsp.buf.format, { desc = "Format" })

vim.keymap.set("n", "<leader>hn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>hp", ":bprev<CR>", { desc = "Prev buffer" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>xx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.keymap.set("n", "<leader>rp", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>")

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Diagnostic keymaps
-- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
-- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- vim.keymap.set("n", "ge", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "gep", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "gen", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "gel", "<cmd>Lspsaga show_line_diagnostics<cr>", { desc = "Open diagnostics line" })
-- vim.keymap.set("n", "gle", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
vim.keymap.set("n", "geb", "<cmd>Lspsaga show_buf_diagnostics<cr>", { desc = "Open diagnostics buffer" })
vim.keymap.set("n", "gew", "<cmd>Lspsaga show_workspace_diagnostics<cr>", { desc = "Open diagnostics workspace" })
