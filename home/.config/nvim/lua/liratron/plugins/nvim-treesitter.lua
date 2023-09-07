return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      -- import nvim-treesitter plugin
      local treesitter = require("nvim-treesitter.configs")

      -- configure treesitter
      treesitter.setup({ -- enable syntax highlighting
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        -- enable indentation
        indent = { enable = true },

        -- enable autotagging (w/ nvim-ts-autotag plugin)
        autotag = { enable = true },
        
        -- ensure these language parsers are installed
        ensure_installed = {
          "json",
          "javascript",
          "typescript",
          "tsx",
          "yaml",
          "html",
          "css",
          "markdown",
          "markdown_inline",
          "svelte",
          "graphql",
          "bash",
          "lua",
          "vim",
          "go",
          "java",
          "kotlin",
          "lua",
          "dockerfile",
          "gitignore",
        },
        
        -- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
        context_commentstring = {
          enable = true,
          enable_autocmd = false,
        },
        
        -- auto install above language parsers
        auto_install = true,
      })
    end,
  },
}
