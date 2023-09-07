return {
  "jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- import null-ls plugin
    local null_ls = require("null-ls")

    -- to setup format on save
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    -- configure null_ls
    null_ls.setup({
        sources = {
          -- make sure the source name is supported by null-ls
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
          null_ls.builtins.formatting.gofumpt,
          null_ls.builtins.formatting.goimports,
          null_ls.builtins.formatting.prettier,
        },

        -- configure format on save
        on_attach = function(current_client, bufnr)
          if current_client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({
                      filter = function(client)
                        --  only use null-ls for formatting instead of lsp server
                        return client.name == "null-ls"
                      end,
                      bufnr = bufnr,
                    })
                end,
              })
          end
        end,
      })
  end,
}
