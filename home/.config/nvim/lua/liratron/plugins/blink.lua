return {
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "saghen/blink.compat",
        opts = {},
        version = "*",
        lazy = true,
      },
      "moyiz/blink-emoji.nvim",
      "Kaiser-Yang/blink-cmp-dictionary",
    },

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            gap = 2,
            treesitter = { "lsp" },
            columns = {
              { "kind_icon", "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
          winhighlight = "Normal:None",
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 50,
          window = {
            border = "single",
            winhighlight = "Normal:None,FloatBorder:None,CursorLine:None,BlinkCmpDocSeparator:None",
          },
        },
        ghost_text = {
          enabled = true,
        },
      },
      signature = { enabled = true },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "emoji", "dictionary" },
        providers = {
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            score_offset = 15, -- the higher the number, the higher the priority
            opts = { insert = true }, -- Insert emoji (default) or complete its name
          },
          dictionary = {
            module = "blink-cmp-dictionary",
            name = "Dict",
            score_offset = 20, -- the higher the number, the higher the priority
            enabled = true,
            max_items = 8,
            min_keyword_length = 3,
            opts = {
              get_command = {
                "rg", -- make sure this command is available in your system
                "--color=never",
                "--no-line-number",
                "--no-messages",
                "--no-filename",
                "--ignore-case",
                "--",
                "${prefix}", -- this will be replaced by the result of 'get_prefix' function
                vim.fn.expand("~/.config/dictionary/words"), -- where you dictionary is
              },
              documentation = {
                enable = true, -- enable documentation to show the definition of the word
                get_command = {
                  -- For the word definitions feature
                  -- make sure "wn" is available in your system
                  -- brew install wordnet
                  "wn",
                  "${word}", -- this will be replaced by the word to search
                  "-over",
                },
              },
            },
          },
        },
      },
    },
    opts_extend = {
      "sources.compat",
      "sources.default",
    },
  },
}
