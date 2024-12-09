return {
  "glepnir/lspsaga.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- optional
    "nvim-tree/nvim-web-devicons",     -- optional
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
        sign_priority = 40,
        virtual_text = true,
      },
      lightbulb = {
        enable = false,
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
    })

    local nmap = function(keys, func, desc)
      if desc then
        desc = "LSP: " .. desc
      end

      vim.keymap.set("n", keys, func, { desc = desc })
    end

    nmap("gd", "<cmd>Lspsaga goto_definition<cr>", "[G]oto [D]efinition")
    nmap("gwf", "<cmd>Lspsaga finder<cr>", "[G]oto [W]ord [R]eferences ")
    nmap("gwi", "<cmd>Lspsaga finder imp<cr>", "[G]oto [W]ord [I]mplementation ")
    nmap("ghi", "<cmd>Lspsaga incoming_calls<cr>", "[G]o to [H]ierarchy [I]ncoming")
    nmap("gho", "<cmd>Lspsaga outgoing_calls<cr>", "[G]o to [H]ierarchy [O]utgoing")
    nmap("gpd", "<cmd>Lspsaga peek_definition<cr>", "[G]o to Peek Definition")
    nmap("gpt", "<cmd>Lspsaga peek_type_definition<cr>", "[G]o to Peek Type Definition")
    nmap("gt", "<cmd>Lspsaga goto_type_definition<cr>", "[G]oto [T]ype Definitions")
    nmap("gel", "<cmd>Lspsaga show_line_diagnostics<cr>", "Open diagnostics line")
    nmap("gwe", "<cmd>Lspsaga show_workspace_diagnostics<cr>", "Open diagnostics workspace")
  end,
}
