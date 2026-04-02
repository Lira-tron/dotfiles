return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggle", "DiffviewFocusFiles", "DiffviewRefresh" },
  config = function()
    require("diffview").setup({
      keymaps = {
        view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } } },
        file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } } },
        file_history_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } } },
      },
    })
  end,
  -- Optional: Add keymaps
  keys = {
    { "<leader>gv", ":DiffviewOpen<CR>", desc = "Open Diffview" },
    { "<leader>gV", ":DiffviewOpen origin/mainline<CR>", desc = "Open Diffview mainline" },
  },
}

