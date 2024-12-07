return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    -- Lsp inlay hints
    "lvimuser/lsp-inlayhints.nvim",
    "folke/neodev.nvim",
    "williamboman/mason.nvim",

  },
  opts = {
    diagnostics = {
      underline = false,
      virtual_text = {
        prefix =  "icons" ,
      },
      severity_sort = true,
    },
    inlay_hints = {
      enabled = true,
    },
    servers = {
      jdtls = {},
    },
    setup = {
      jdtls = function()
        return true -- avoid duplicate servers
      end,
    },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- configure lsp inlay hints
    local ih = require("lsp-inlayhints")
    ih.setup({
      only_current_line = true,

      eol = {
        right_align = true,
      },
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = "E ", Warn = "W ", Hint = "H ", Info = "I " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    local on_attach = function(c, bufnr)
      local nmap = function(keys, func, desc)
        if desc then
          desc = "LSP: " .. desc
        end

        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
      end

      nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
      nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
      nmap("K", vim.lsp.buf.hover, "Hover Documentation")
      nmap("gk", vim.lsp.buf.signature_help, "Signature Documentation")
      nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      nmap("gwa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
      nmap("gwr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
      nmap("gwl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, "[W]orkspace [L]ist Folders")
      -- inlay hints
      ih.on_attach(c, bufnr)
    end

    local servers = {
      --Bash
      bashls = {},

      -- C/C++
      clangd = {},

      yamlls = {},
      taplo = {},
      marksman = {},
      -- jqls = {
      --   json = {
      --     inlayHints = {
      --     },
      --     usePlaceholders = true,
      --   }
      -- },

      -- python
      -- pylsp = {},
      -- ruff_lsp = {},

      -- HTML/HTMX
      html = {},
      -- htmx = {},

      -- Go
      gopls = {
        go = {
          inlayHints = {
            parameterHints = true,
            typeHints = true,
            chainingHints = false,
            -- maxLength = 80,
          },
          completeUnimported = true,
          usePlaceholders = true,
          gofumpt = true,
          analyses = {
            unusedparams = true,
            unusedwrite = true,
            unusedany = true,
          },
        },
      },
      templ = {
        templ = {
          inlayHints = {
            chainingHints = true,
            parameterHints = true,
            typeHints = true,
          },
          cmd = { "templ", "lsp" },
          filetypes = { "templ" },
        },
      },

      -- Javascript/Typescript
      tsserver = {
        javascript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
          },
        },

        typescript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = false,
          },
        },

        typescriptreact = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = false,
          },
        },
      },
      tailwindcss = {
        filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "templ" },
        init_options = { userLanguages = { templ = "html" } },
      },

      -- Lua
      lua_ls = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          hint = {
            enable = false,
          },
          diagnostics = {
            disable = { "missing-fields", "incomplete-signature-doc" },
          },
        },
      },
      luau_lsp = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          hint = {
            enable = false,
          },
          diagnostics = {
            disable = { "missing-fields", "incomplete-signature-doc" },
          },
        },
      },

      -- rust
      rust_analyzer = {
        rust = {
          inlayHints = {
            chainingHints = true,
            parameterHints = true,
            typeHints = true,
          },
        },
      },

      -- jdtls = {},

      solargraph = {
        --     root_dir = require('lspconfig').util.root_pattern("packageInfo", "Gemfile", ".git", ".") or
        --         require("lspconfig").util.path.dirname(vim.api.nvim_buf_get_name(0)),
        --     settings = {
        --       solargraph = {
        --         autoformat = false,
        --         formatting = false,
        --         completion = true,
        --         diagnostic = true,
        --         folding = true,
        --         references = true,
        --         rename = true,
        --         symbols = true
        --       }
        --     }
      },
    }

        -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- for nvim-ufo fold
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

  -- Ensure the servers above are installed
    local mason_lspconfig = require("mason-lspconfig")

    mason_lspconfig.setup_handlers({
      function(server_name)
        require("lspconfig")[server_name].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          settings = servers[server_name],
        })
      end,
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
