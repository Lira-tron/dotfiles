local modes = { "n", "c", "v", "t" }

return {
  "lmilojevicc/herdr-splits.nvim",
  cond = vim.env.HERDR_ENV == "1",
  event = "VeryLazy",
  config = function()
    require("herdr-splits").setup({
      auto_sync_herdr = true,
      resize_keys = {
        left = "<C-M-h>",
        down = "<C-M-j>",
        up = "<C-M-k>",
        right = "<C-M-l>",
      },
    })
  end,
  keys = {
    {
      "<C-h>",
      function()
        require("herdr-splits").move_cursor_left()
      end,
      mode = modes,
      desc = "Navigate left",
    },
    {
      "<C-j>",
      function()
        require("herdr-splits").move_cursor_down()
      end,
      mode = modes,
      desc = "Navigate down",
    },
    {
      "<C-k>",
      function()
        require("herdr-splits").move_cursor_up()
      end,
      mode = modes,
      desc = "Navigate up",
    },
    {
      "<C-l>",
      function()
        require("herdr-splits").move_cursor_right()
      end,
      mode = modes,
      desc = "Navigate right",
    },
    {
      "<C-M-h>",
      function()
        require("herdr-splits").resize_left()
      end,
      mode = modes,
      desc = "Resize left",
    },
    {
      "<C-M-j>",
      function()
        require("herdr-splits").resize_down()
      end,
      mode = modes,
      desc = "Resize down",
    },
    {
      "<C-M-k>",
      function()
        require("herdr-splits").resize_up()
      end,
      mode = modes,
      desc = "Resize up",
    },
    {
      "<C-M-l>",
      function()
        require("herdr-splits").resize_right()
      end,
      mode = modes,
      desc = "Resize right",
    },
  },
}
