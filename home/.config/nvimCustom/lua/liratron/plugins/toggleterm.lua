return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("toggleterm").setup()
    local terminal = require("toggleterm.terminal").Terminal

    local toggle_float = function()
      local float = terminal:new({ direction = "float" })
      return float:toggle()
    end

    local toggle_lazygit = function()
      local lazygit = terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        start_in_insert = true,
        float_opts = {
          border = "none",
          width = 100000,
          height = 100000,
        },
        on_open = function(_)
          vim.cmd("startinsert!")
        end,
        on_close = function(_) end,
        count = 99,
      })
      return lazygit:toggle()
    end
    vim.keymap.set({ "v", "n" }, "<leader>gg", toggle_lazygit, { desc = "[T]erminal [L]azygit" })
    vim.keymap.set({ "v", "n" }, "<leader>tf", toggle_float, { desc = "[T]erminal [T]erminal" })
    vim.keymap.set(
      { "v", "n" },
      "<leader>tt",
      "<cmd>ToggleTerm direction=horizontal <cr>",
      { desc = "[T]erminal [H]orizontal" }
    )
    vim.keymap.set(
      { "v", "n" },
      "<leader>tv",
      "<cmd>ToggleTerm direction=vertical size=" .. vim.o.columns * 0.4 .. " <CR>",
      { desc = "[T]erminal [V]ertical" }
    )
    function _G.set_terminal_keymaps()
      local opts = { noremap = true }
      vim.api.nvim_buf_set_keymap(0, "t", "<M-esc>", [[<C-\><C-n>]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
      vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
    end

    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
  end,
}
