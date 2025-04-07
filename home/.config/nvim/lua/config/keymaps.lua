-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v" }, "gn", "<nop>")
vim.keymap.set({ "n", "v" }, "gN", "<nop>")

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "C-d keep cursor in middle" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "C-u keep cursor in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "search keep cursor in middle" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "search keep cursor in middle" })

vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "gpb", "<cmd>bprevious<cr>", { desc = "[G]o [P]rev [B]uffer" })
vim.keymap.set("n", "gnb", "<cmd>bnext<cr>", { desc = "[G]o [N]ext [B]uffer" })

local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

vim.keymap.set("n", "gnd", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "gpd", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "gne", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "gpe", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "gnw", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "gpw", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
