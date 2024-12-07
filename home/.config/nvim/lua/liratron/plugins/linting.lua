return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "pylint" },
      go = { "golangcilint", "cspell" },
      java = { "checkstyle" },
      kotlin = { "detekt" },
      markdown = { "markdownlint", "write_good" },
      yaml = { "yamllint" },
      lua = { "selene" },
    }

    vim.keymap.set("n", "gll", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
