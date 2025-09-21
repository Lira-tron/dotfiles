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
      { "<leader>mg", "<cmd>Glow<CR>", { desc = "[M]ardown [G]low" } },
    },
    config = true,
    cmd = "Glow",
  },
}
