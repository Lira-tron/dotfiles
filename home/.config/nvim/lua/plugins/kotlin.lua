return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable kotlin_language_server from LazyVim extra
        kotlin_language_server = { enabled = false },
      },
      -- Custom setup for kotlin_lsp
      setup = {
        kotlin_lsp = function()
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")

          lspconfig.kotlin_lsp.setup({
            cmd_env = {
              JAVA_HOME =  os.getenv("JAVA_HOME"),
            },
            root_dir = function(fname)
              return vim.fs.root(fname, {
                "settings.gradle",
                "settings.gradle.kts",
                "gradlew",
              }) or vim.fs.root(fname, {
                "build.gradle",
                "build.gradle.kts",
                "pom.xml",
                "build.xml",
              }) or vim.fs.dirname(fname)
            end,
            on_attach = function(client)
              client.server_capabilities.documentFormattingProvider = false
            end,
          })
          return true -- Return true to indicate we handled the setup
        end,
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "kotlin-lsp", "ktfmt", "ktlint" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        kotlin = { "ktfmt", "ktlint" },
      },
    },
  },
}
