return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  -- opts = {
  --     setup = {
  --         -- disable jdtls config from lspconfig
  --         jdtls = function()
  --             return true
  --         end,
  --     }
  -- },
  cmd = function ()
        local lspconfig = require 'lspconfig'
        local configs = require 'lspconfig.configs'
        if not configs.codewhisperer then
            configs.codewhisperer = {
                default_config = {
                    -- Add the codewhisperer to our PATH or BIN folder
                    cmd = { "cwls" },
                    root_dir = lspconfig.util.root_pattern("packageInfo", "package.json", "tsconfig.json", "jsconfig.json", ".git"),
                    filetypes = { 'java', 'python', 'typescript', 'javascript', 'csharp', 'ruby', 'kotlin', 'shell', 'sql', 'c', 'cpp', 'go', 'rust', 'lua' },
                },
            }
        end
        lspconfig.codewhisperer.setup {}
    end,
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local opts = { noremap = true, silent = true }
    local on_attach = function(client, bufnr)
      opts.buffer = bufnr

      local nmap = function(keys, func, desc)
        if desc then
          desc = "LSP: " .. desc
        end

        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
      end

      -- nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
      nmap("<leader>rn", "<cmd>Lspsaga rename<cr>", "[R]e[n]ame")
      -- nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
      nmap("<leader>ca", "<cmd>Lspsaga code_action<cr>", "[C]ode [A]ction")

      nmap("gd", "<cmd>Lspsaga goto_definition<cr>", "[G]oto [D]efinition")
      nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
      nmap("gwf", "<cmd>Lspsaga finder<cr>", "[G]oto [W]ord [R]eferences ")
      nmap("gwi", "<cmd>Lspsaga finder imp<cr>", "[G]oto [W]ord [I]mplementation ")
      nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
      nmap("gs", require("telescope.builtin").lsp_document_symbols, "[G]o to [D]ocument [S]ymbols")
      nmap("gws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[G]o to [D]ynamic  workspace [S]ymbols")

      -- See `:help K` for why this keymap
      -- nmap("K", vim.lsp.buf.hover, "Hover Documentation")
      nmap("K", "<cmd>Lspsaga hover_doc<cr>", "Hover Documentation")
      nmap("gk", vim.lsp.buf.signature_help, "Signature Documentation")

      nmap("ghi", "<cmd>Lspsaga incoming_calls<cr>", "[G]o to [H]ierarchy [I]ncoming")
      nmap("gho", "<cmd>Lspsaga outgoing_calls<cr>", "[G]o to [H]ierarchy [O]utgoing")

      nmap("gpd", "<cmd>Lspsaga peek_definition<cr>", "[G]o to Peek Definition")
      nmap("gpt", "<cmd>Lspsaga peek_type_definition<cr>", "[G]o to Peek Type Definition")

      -- Lesser used LSP functionality
      nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      nmap("gt", "<cmd>Lspsaga goto_type_definition<cr>", "[G]oto [T]ype Definitions")
      nmap("gwa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
      nmap("gwr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
      nmap("gwl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, "[W]orkspace [L]ist Folders")

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
        vim.lsp.buf.format()
      end, { desc = "Format current buffer with LSP" })
    end

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = "E ", Warn = "W ", Hint = "H ", Info = "I " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- configure html server
    lspconfig["html"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- configure typescript server with plugin
    lspconfig["ts_ls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- configure graphql language server
    lspconfig["graphql"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    })

    -- configure yaml server
    lspconfig["yamlls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- configure python server
    lspconfig["pyright"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- lspconfig["jdtls"].setup({
    --     capabilities = capabilities,
    --     on_attach = on_attach,
    -- })

    lspconfig["gopls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        gopls = {
          gofumpt = true,
          completeUnimported = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
        },
      },
      flags = {
        debounce_text_changes = 150,
      },
    })

    -- configure lua server (with special settings)
    lspconfig["lua_ls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = { -- custom settings for lua
        Lua = {
          -- make the language server recognize "vim" global
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            -- make language server aware of runtime files
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
        },
      },
    })

    vim.diagnostic.config({
      virtual_text = true,
      severity_sort = true,
      float = {
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
  end,
}
