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
      "giuxtaposition/blink-cmp-copilot",
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
              { "kind_icon", "label", gap = 1 },
              { "source_name" },
            },
          },
          winhighlight = "Normal:None",
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 10,
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
        default = { "lsp", "copilot", "path", "snippets", "buffer", "emoji", "dictionary" },
        providers = {
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            score_offset = -24, -- the higher the number, the higher the priority
            opts = { insert = true }, -- Insert emoji (default) or complete its name
          },
          dictionary = {
            module = "blink-cmp-dictionary",
            name = "Dict",
            score_offset = -20, -- the higher the number, the higher the priority
            enabled = true,
            max_items = 8,
            min_keyword_length = 3,
            opts = {
              dictionary_directories = { vim.fn.expand("~/.config/dictionaries") },
            },
          },
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
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
