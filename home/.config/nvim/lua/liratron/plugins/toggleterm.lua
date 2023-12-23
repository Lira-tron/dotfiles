return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("toggleterm").setup()
    local terminal = require("toggleterm.terminal").Terminal

    -- local toggle_float = function()
    --   local float = terminal:new({ direction = "float" })
    --   return float:toggle()
    -- end

    local toggle_lazygit = function()
      local lazygit = terminal:new({ cmd = "lazygit", direction = "float" })
      return lazygit:toggle()
    end
    vim.keymap.set({ "v", "n" }, "<leader>tl", toggle_lazygit, { desc = "[T]erminal [L]azygit" })
  end,
}
