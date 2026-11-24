return {
  "echasnovski/mini.files",
  opts = {
    options = {
      use_as_default_explorer = true,
      -- If set to false, files are moved to the trash directory
      -- To get this dir run :echo stdpath('data')
      -- ~/.local/share/neobean/mini.files/trash
      permanent_delete = false,
    },
    mappings = {
      close = "<Esc>",
      go_in = "l",
      -- This opens the file, but quits out of mini.files (default L)
      go_in_plus = "<CR>",
      -- I swapped the following 2 (default go_out: h)
      -- go_out_plus: when you go out, it shows you only 1 item to the right
      -- go_out: shows you all the items to the right
      go_out = "H",
      go_out_plus = "h",
      -- Default <BS>
      reset = "<BS>",
      -- Default @
      reveal_cwd = ".",
      show_help = "g?",
      -- Default =
      synchronize = "s",
      trim_left = "<",
      trim_right = ">",

      -- close = "q",
      -- go_in = "l",
      -- go_in_plus = "L",
      -- go_out = "h",
      -- go_out_plus = "H",
      -- mark_goto = "'",
      -- mark_set = "m",
      -- reset = "<BS>",
      -- reveal_cwd = "@",
      -- show_help = "g?",
      -- synchronize = "=",
      -- trim_left = "<",
      -- trim_right = ">",
    },
  },
  keys = {
    { "<leader>fm", false },
    { "<leader>fM", false },
    {
      "<leader>e",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (Directory of Current File)",
    },
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.uv.cwd(), true)
      end,
      desc = "Open mini.files (cwd)",
    },
  },
}
