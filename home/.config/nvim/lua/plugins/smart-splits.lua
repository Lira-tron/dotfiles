return {
  {
    "mrjones2014/smart-splits.nvim",
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "v" }, desc = "Move to left pane" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "v" }, desc = "Move to below pane" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "v" }, desc = "Move to above pane" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "v" }, desc = "Move to right pane" },
    },
  },
}
