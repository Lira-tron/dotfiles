return {
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      -- Switch to other tmux panes not only when in normal mode, but also
      -- insert and visual mode
      { "<C-h>", '<cmd>TmuxNavigateLeft("n")<cr>', mode = { "n", "v", "i" }, desc = "TmuxNavigateLeft" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "v", "i" }, desc = "TmuxNavigateDown" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "v", "i" }, desc = "TmuxNavigateUp" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "v", "i" }, desc = "TmuxNavigateRight" },
      { "<C-,>", "<cmd>TmuxNavigatePrevious<cr>", mode = { "n", "v", "i" }, desc = "TmuxNavigatePrevious" },
    },
  },
}
