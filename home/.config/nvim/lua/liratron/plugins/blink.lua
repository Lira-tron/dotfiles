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
        use_nvim_cmp_as_default = false,
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
          auto_show_delay_ms = 100,
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
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
    opts_extend = {
      "sources.compat",
      "sources.default",
    },
  },
}
