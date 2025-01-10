return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    require("mini.icons").setup()
    require("mini.move").setup({

      keys = {
        { "H", mode = "v", desc = "Move visual block left" },
        { "L", mode = "v", desc = "Move visual block right" },
        { "J", mode = "v", desc = "Move visual block down" },
        { "K", mode = "v", desc = "Move visual block up" },
      },
      opts = {
        mappings = {
          -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
          left = "H",
          right = "L",
          down = "J",
          up = "K",
        },
      },
    })
    require("mini.ai").setup()
    require("mini.indentscope").setup()
    require("mini.splitjoin").setup()
    require("mini.pairs").setup()
    require("mini.surround").setup({
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    })
  end,
}
