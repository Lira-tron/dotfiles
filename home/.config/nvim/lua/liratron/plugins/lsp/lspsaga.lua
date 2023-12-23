return {
  "glepnir/lspsaga.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- optional
    "nvim-tree/nvim-web-devicons", -- optional
  },
  config = function()
    local lspsaga = require("lspsaga")
    lspsaga.setup({
      scroll_preview = {
        scroll_down = "<C-d>",
        scroll_up = "<C-u>",
      },
      finder = {
        keys = {
          vsplit = "v",
          split = "s",
          tabe = "t",
          toggle_or_open = "<CR>",
          quit = "<ESC>",
        },
      },
      definition = {
        keys = {
          vsplit = "v",
          split = "s",
          tabe = "t",
          toggle_or_open = "<CR>",
          quit = "<ESC>",
        },
      },
      code_action = {
        extend_gitsigns = false,
        num_shortcut = true,
        keys = {
          quit = "<ESC>",
          exec = "<CR>",
        },
      },
      lightbulb = {
        enable = true,
        enable_in_insert = false,
        sign = true,
        sign_priority = 40,
        virtual_text = true,
      },
      diagnostic = {
        twice_into = false,
        show_code_action = true,
        show_source = true,
        keys = {
          exec_action = "<CR>",
          quit = "<ESC>",
        },
      },
      rename = {
        keys = {
          quit = "<ESC>",
          exec = "<CR>",
        },
        in_select = false,
      },
      outline = {
        show_detail = true,
        auto_preview = true,
        auto_refresh = true,
        auto_close = true,
        custom_sort = nil,
        keys = {
          jump = "<BR>",
          quit = "<ESC>",
        },
      },
      callhierarchy = {
        show_detail = true,
        keys = {
          toggle_or_open = "<BR>",
          vsplit = "v",
          split = "s",
          tabe = "t",
          quit = "<ESC>",
          expand_collapse = "u",
        },
      },
      symbol_in_winbar = {
        enable = false,
        separator = " ",
        hide_keyword = true,
        show_file = false,
        folder_level = 2,
      },
      ui = {
        theme = "round",
        -- border type can be single,double,rounded,solid,shadow.
        border = "single",
        winblend = 0,
        expand = "",
        collapse = "",
        preview = " ",
        code_action = " ",
        diagnostic = "  ",
        incoming = " ",
        outgoing = " ",
        finder = "  ",
      },
      -- diagnostic_header_icon = "   ",
      -- -- code action title icon
      -- code_action_icon = " ",
      -- code_action_prompt = { enable = true, sign = true, sign_priority = 40, virtual_text = true },
      -- finder_definition_icon = "  ",
      -- finder_reference_icon = "  ",
      -- max_preview_lines = 20,
      --
      -- hover = {
      --   max_width = 0.7,
      -- },
      -- definition_preview_icon = "  ",
      -- border_style = "single",
      -- rename_prompt_prefix = "➤",
      -- server_filetype_map = {},
      -- diagnostic_prefix_format = "%d. ",
    })
  end,
}
