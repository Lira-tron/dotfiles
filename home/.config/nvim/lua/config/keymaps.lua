-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v" }, "gn", "<nop>")
vim.keymap.set({ "n", "v" }, "gN", "<nop>")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "[b")


vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "C-d keep cursor in middle" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "C-u keep cursor in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "search keep cursor in middle" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "search keep cursor in middle" })

vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "gpb", "<cmd>bprevious<cr>", { desc = "[G]o [P]rev [B]uffer" })
vim.keymap.set("n", "gnb", "<cmd>bnext<cr>", { desc = "[G]o [N]ext [B]uffer" })


