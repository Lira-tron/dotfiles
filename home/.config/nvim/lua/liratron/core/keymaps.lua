vim.g.mapleader = " "

-- vim.keymap.set('n', '<leader>w', ':w<CR>')

vim.keymap.set("n", "J", "mzJ`z", { desc = "Paste below line at the end of the line without moving cursor " })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "C-d keep cursor in middle" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "C-u keep cursor in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "search keep cursor in middle" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "search keep cursor in middle" })

-- greatest remap ever
vim.keymap.set("x", "<leader>P", [["_dP]], { desc = "Paste without having it in buffer" })

vim.keymap.set({ "n", "v" }, "<leader>D", [["_d]])

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
-- vim.keymap.set({ "n", "v" }, "<leader>rf", vim.lsp.buf.format, { desc = "Format" })


-- Movment remaps to deal with wordwrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Fixes word wrapping for k" })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Fixes word wrapping for j" })

vim.keymap.set("v", "<", "<gv", { desc = "Stay in visual mode after indenting with <" })
vim.keymap.set("v", ">", ">gv", { desc = "Stay in visual mode after indenting with >" })


-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>x", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
vim.keymap.set("n", "<leader>tnt", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
vim.keymap.set("n", "<leader>tpt", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
vim.keymap.set("n", "<leader>tnb", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>tpb", ":bprev<CR>", { desc = "Prev buffer" })

vim.keymap.set({ "n", "v" }, "<leader>rp", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "gpe", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "gne", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })

vim.keymap.set("n", "<leader>Xa", "<cmd>source %<CR>", {desc = "Reloads lua config"})
vim.keymap.set("n", "<leader>Xf", ":.lua<CR>", {desc = "Reloads current line"})
vim.keymap.set("v", "<leader>Xf", ":lua<CR>", {desc = "Reloads selected"})

