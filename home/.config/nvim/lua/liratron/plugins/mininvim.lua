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
    require("mini.sessions").setup()
    require("mini.pairs").setup()
  end,
}
