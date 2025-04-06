return {
  "mrjones2014/smart-splits.nvim",
  init = function()
    local splits = require("smart-splits")
    -- local modes = { "n", "c", "v", "t" }

    -- resizing splits
    -- these keymaps will also accept a range,
    -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
    vim.keymap.set("n", "<C-M-h>", splits.resize_left)
    vim.keymap.set("n", "<C-M-j>", splits.resize_down)
    vim.keymap.set("n", "<C-M-k>", splits.resize_up)
    vim.keymap.set("n", "<C-M-l>", splits.resize_right)
    -- moving between splits
    vim.keymap.set("n", "<C-h>", splits.move_cursor_left)
    vim.keymap.set("n", "<C-j>", splits.move_cursor_down)
    vim.keymap.set("n", "<C-k>", splits.move_cursor_up)
    vim.keymap.set("n", "<C-l>", splits.move_cursor_right)
    vim.keymap.set("n", "<C-,>", splits.move_cursor_previous)
    -- swapping buffers between windows
    vim.keymap.set("n", "<C-w>H", splits.swap_buf_left)
    vim.keymap.set("n", "<C-w>J", splits.swap_buf_down)
    vim.keymap.set("n", "<C-w>K", splits.swap_buf_up)
    vim.keymap.set("n", "<C-w>L", splits.swap_buf_right)
  end,
}
