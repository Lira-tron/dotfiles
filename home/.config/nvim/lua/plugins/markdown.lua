-- Launch glow with a chosen glamour style. glow.nvim spawns `glow` with stdout
-- on a pipe (not a TTY), so charm/termenv drops color unless forced, and even
-- forced it caps at ANSI-16. The float is an nvim :terminal that paints those
-- 16 indices from g:terminal_color_0..15. Our style JSONs use ANSI *index*
-- strings ("0".."15") instead of hex, so each markdown element maps to an exact
-- slot, and we feed the float a curated palette so those slots are exact theme
-- colors. Headings follow render-markdown's warm gradient: H1 red, H2 orange,
-- H3 yellow, H4 green, H5 aqua, H6 blue (slot 9 is repurposed as orange, which
-- neither theme's standard 16-color palette otherwise provides).
--
-- The palette is set just for this spawn and restored immediately after (nvim
-- snapshots g:terminal_color_* when the terminal is created), so the float gets
-- the theme colors while the rest of the editor is untouched.
local function glow_with(style, palette)
  local cfg = vim.fn.stdpath("config")
  require("glow").setup({
    width_ratio = 1,
    height_ratio = 1,
    width = 1000,
    height = 1000,
    style = style and (cfg .. "/glow/" .. style .. ".json") or vim.o.background,
  })

  local force, colorterm = vim.env.CLICOLOR_FORCE, vim.env.COLORTERM
  local saved_pal = {}
  if palette then
    for i = 0, 15 do
      saved_pal[i] = vim.g["terminal_color_" .. i]
      vim.g["terminal_color_" .. i] = palette[i + 1]
    end
  end
  vim.env.CLICOLOR_FORCE = "1"
  vim.env.COLORTERM = "truecolor"

  vim.cmd("Glow") -- synchronous: opens the terminal, snapshotting env + palette

  if palette then
    for i = 0, 15 do
      vim.g["terminal_color_" .. i] = saved_pal[i]
    end
  end
  vim.env.CLICOLOR_FORCE = force
  vim.env.COLORTERM = colorterm
end

-- Ghostty terminal palette (Gruvbox Material), copied verbatim from the Ghostty
-- config so the float matches the actual terminal. This is the default. Slot 0
-- (#141617) doubles as the code background; slot 8 uses the brighter grey.
local ghostty_palette = {
  "#141617", "#ea6962", "#a9b665", "#d8a657", -- bg red green yellow
  "#7daea3", "#d3869b", "#89b482", "#ddc7a1", -- blue magenta cyan fg
  "#928374", "#ea6962", "#a9b665", "#d8a657", -- grey red green yellow
  "#7daea3", "#d3869b", "#89b482", "#ddc7a1", -- blue magenta cyan fg
}

-- Everforest float palette. Mirrors the live colorscheme's terminal colors but
-- injects Everforest's orange (#e69875) at slot 9 so H2 renders orange like the
-- editor (the standard palette has no orange). Slot 8 = code background.
local everforest_palette = {
  "#414b50", "#e67e80", "#a7c080", "#dbbc7f", -- bg red green yellow
  "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa", -- blue magenta cyan fg
  "#2e383c", "#e69875", "#a7c080", "#dbbc7f", -- code-bg ORANGE green yellow
  "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa", -- blue magenta cyan fg
}

-- Gruvbox-dark float palette, with Gruvbox orange (#fe8019) at slot 9 for H2.
local gruvbox_palette = {
  "#282828", "#cc241d", "#98971a", "#d79921", -- bg red green yellow
  "#458588", "#b16286", "#689d6a", "#a89984", -- blue magenta cyan fg
  "#3c3836", "#fe8019", "#b8bb26", "#fabd2f", -- code-bg ORANGE green yellow
  "#83a598", "#d3869b", "#8ec07c", "#ebdbb2", -- blue magenta cyan fg
}

return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<CR>",
        desc = "[M]arkdown [P]review Brwoser Toggle",
      },
      -- { "<leader>mpS", "<cmd>MarkdownPreviewStop<CR>", desc = "[M]arkdown [P]review Browser Stop" },
    },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.nvim",
    }, -- if you use the mini.nvim suite
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      bullet = {
        -- Turn on / off list bullet rendering
        enabled = true,
      },
      checkbox = {
        -- Turn on / off checkbox state rendering
        enabled = true,
        -- Determines how icons fill the available space:
        --  inline:  underlying text is concealed resulting in a left aligned icon
        --  overlay: result is left padded with spaces to hide any additional text
        position = "inline",
        unchecked = {
          -- Replaces '[ ]' of 'task_list_marker_unchecked'
          icon = "   󰄱 ",
          -- Highlight for item associated with unchecked checkbox
          scope_highlight = nil,
        },
        checked = {
          -- Replaces '[x]' of 'task_list_marker_checked'
          icon = "   󰱒 ",
          -- Highlight for item associated with checked checkbox
          scope_highlight = nil,
        },
      },
      html = {
        -- Turn on / off all HTML rendering
        enabled = true,
        comment = {
          -- Turn on / off HTML comment concealing
          conceal = false,
        },
      },
      link = {
        image = "󰥶 ",
        custom = {
          youtu = { pattern = "youtu%.be", icon = "󰗃 " },
        },
      },
      heading = {
        sign = false,
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      },
    },
  },
  {
    "ellisonleao/glow.nvim",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "markdown" },
    keys = {
      -- Default: Ghostty palette (Gruvbox Material) -- matches the real terminal.
      {
        "<leader>mg",
        function()
          glow_with("ghostty", ghostty_palette)
        end,
        desc = "[M]arkdown [G]low (ghostty)",
      },
      -- Compare: Gruvbox style + Gruvbox palette (scoped to this float only).
      {
        "<leader>mG",
        function()
          glow_with("gruvbox", gruvbox_palette)
        end,
        desc = "[M]arkdown [G]low (gruvbox)",
      },
      -- Compare: glow's built-in default style, no overrides.
      {
        "<leader>md",
        function()
          glow_with(nil)
        end,
        desc = "[M]arkdown glow ([d]efault style)",
      },
    },
    -- setup() is called per-launch by glow_with(); config=true would just call
    -- setup() again with defaults, which is harmless but redundant.
    config = function() end,
    cmd = "Glow",
  },
}
