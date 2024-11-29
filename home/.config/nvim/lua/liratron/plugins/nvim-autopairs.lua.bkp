return {
  "windwp/nvim-autopairs",
  event = { "InsertEnter" },
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  config = function()
    -- import nvim-autopairs
    local autopairs = require("nvim-autopairs")

    -- configure autopairs
    autopairs.setup({
      check_ts = true, -- enable treesitter
      -- ts_config = {
      --   lua = { "string" }, -- don't add pairs in lua string treesitter nodes
      --   javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
      --   java = false, -- don't check treesitter on java
      -- },
      map_cr = true, --  map <CR> on insert mode
      map_complete = true, -- it will auto insert `(` (map_char) after select function or method item
      auto_select = false, -- auto select first item
      map_char = {
        -- modifies the function or method delimiter by filetypes
        all = "(",
        tex = "{",
      },
    })

    -- import nvim-autopairs completion functionality
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")

    -- import nvim-cmp plugin (completions plugin)
    local cmp = require("cmp")

    -- make autopairs and completion work together
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}
