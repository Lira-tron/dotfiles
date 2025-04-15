return {
  "saghen/blink.cmp",
  dependencies = {
    "moyiz/blink-emoji.nvim",
    "Kaiser-Yang/blink-cmp-dictionary",
    "giuxtaposition/blink-cmp-copilot",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },

      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },

      ["<S-k>"] = { "scroll_documentation_up", "fallback" },
      ["<S-j>"] = { "scroll_documentation_down", "fallback" },

      ["<C-space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
      ["<C-e>"] = { "cancel" },
      ["<Esc>"] = { "cancel", "fallback" },
    },
    signature = { enabled = true },
    cmdline = {
      enabled = true,
    },

    completion = {
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
    },
    sources = {
      default = {
        "copilot",
        "emoji",
        "dictionary",
      },
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
}
