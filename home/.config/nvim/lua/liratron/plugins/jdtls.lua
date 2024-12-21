return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    local jdtls = require("jdtls")

    local cache_vars = {}

    local root_dir = jdtls.setup.find_root({ "packageInfo" }, "Config")

    local java_cmds = vim.api.nvim_create_augroup("java_cmds", { clear = true })

    local ws_folders_jdtls = {}

    if root_dir then
      local file = io.open(root_dir .. "/.bemol/ws_root_folders")

      if file then
        for line in file:lines() do
          table.insert(ws_folders_jdtls, "file://" .. line)
        end
        file:close()
      end
    end

    local features = {
      -- change this to `true` to enable codelens
      codelens = true,

      -- change this to `true` if you have `nvim-dap`,
      -- `java-test` and `java-debug-adapter` installed
      debugger = true,
    }

    local function get_jdtls_paths()
      if cache_vars.paths then
        return cache_vars.paths
      end

      local path = {}

      path.data_dir = vim.fn.stdpath("cache") .. "/nvim-jdtls"

      local jdtls_install = require("mason-registry").get_package("jdtls"):get_install_path()

      path.java_agent = jdtls_install .. "/lombok.jar"
      path.launcher_jar = vim.fn.glob(jdtls_install .. "/plugins/org.eclipse.equinox.launcher_*.jar")

      if vim.fn.has("mac") == 1 then
        path.platform_config = jdtls_install .. "/config_mac"
      elseif vim.fn.has("unix") == 1 then
        path.platform_config = jdtls_install .. "/config_linux"
      elseif vim.fn.has("win32") == 1 then
        path.platform_config = jdtls_install .. "/config_win"
      end

      path.bundles = {}

      ---
      -- Include java-test bundle if present
      ---
      local java_test_path = require("mason-registry").get_package("java-test"):get_install_path()

      local java_test_bundle = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n")

      if java_test_bundle[1] ~= "" then
        vim.list_extend(path.bundles, java_test_bundle)
      end

      ---
      -- Include java-debug-adapter bundle if present
      ---
      local java_debug_path = require("mason-registry").get_package("java-debug-adapter"):get_install_path()

      local java_debug_bundle =
        vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n")

      if java_debug_bundle[1] ~= "" then
        vim.list_extend(path.bundles, java_debug_bundle)
      end

      ---
      -- Useful if you're starting jdtls with a Java version that's
      -- different from the one the project uses.
      ---
      path.runtimes = {
        {
          name = "JavaSE-17",
          path = vim.fn.expandcmd("$JAVA_HOME_17"),
          default = true,
        },
        {
          name = "JavaSE-11",
          path = vim.fn.expandcmd("$JAVA_HOME_11"),
          default = false,
        },
      }
      cache_vars.paths = path

      return path
    end

    local function enable_codelens(bufnr)
      pcall(vim.lsp.codelens.refresh)

      vim.api.nvim_create_autocmd("BufWritePost", {
        buffer = bufnr,
        group = java_cmds,
        desc = "refresh codelens",
        callback = function()
          pcall(vim.lsp.codelens.refresh)
        end,
      })
    end

    local function enable_debugger(bufnr)
      require("jdtls").setup_dap({ hotcodereplace = "auto" })
      require("jdtls.dap").setup_dap_main_class_configs()
    end

    local function jdtls_on_attach(client, bufnr)
      if features.debugger then
        enable_debugger(bufnr)
      end

      if features.codelens then
        enable_codelens(bufnr)
      end

      -- The following mappings are based on the suggested usage of nvim-jdtls
      -- https://github.com/mfussenegger/nvim-jdtls#usage

      local nmap = function(keys, func, desc)
        if desc then
          desc = "LSP: " .. desc
        end

        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
      end

      nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
      nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
      nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
      nmap("K", vim.lsp.buf.hover, "Hover Documentation")
      nmap("gk", vim.lsp.buf.signature_help, "Signature Documentation")
      nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      nmap("gwa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
      nmap("gwr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
      nmap("gwl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, "[W]orkspace [L]ist Folders")

      -- Unique to jdtls
      nmap("<leader>dt", jdtls.test_nearest_method, "[D]ebug [T]est nearest method")

      nmap("<leader>dT", jdtls.test_class, "[D]ebug [T]est class")
      nmap("<leader>ro", jdtls.organize_imports, "Organize imports")
      nmap("<leader>rec", jdtls.extract_constant, "Extract constant")
      nmap("<leader>rev", jdtls.extract_variable, "Extract variable")
      vim.keymap.set("v", "<leader>rem", function()
        jdtls.extract_method(true)
      end, { buffer = true, desc = "Extract to method" })
    end

    local function jdtls_setup(event)
      local path = get_jdtls_paths()
      local data_dir = path.data_dir .. "/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

      if cache_vars.capabilities == nil then
        jdtls.extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

        local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
        cache_vars.capabilities = vim.tbl_deep_extend(
          "force",
          vim.lsp.protocol.make_client_capabilities(),
          ok_cmp and cmp_lsp.default_capabilities() or {}
        )
      end

      -- The command that starts the language server
      -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
      local cmd = {
        -- 💀
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-javaagent:" .. path.java_agent,
        "-Xms2g",
        "-Xmx4g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        -- 💀
        "-jar",
        path.launcher_jar,

        -- 💀
        "-configuration",
        path.platform_config,

        -- 💀
        "-data",
        data_dir,
      }

      local lsp_settings = {
        java = {
          eclipse = {
            downloadSources = true,
          },
          cleanup = {
            actionsOnSave = {
              -- adds the deprecated annotation to classes/fields/methods that are marked deprecated in the javadoc.
              "addDeprecated",
              -- adds the 'final' modifier where possible.
              "addFinalModifier",
              -- adds the override annotation to all methods that override any parent method.
              "addOverride",
              -- inverts calls to Object.equals(Object) and String.equalsIgnoreCase(String) to avoid useless null pointer exception.
              "invertEquals",
              -- several actions to clean up lambda expression.
              "lambdaExpression",
              -- prefixes all (non-static) field and method accesses with this.
              -- 'qualifyMembers',
              -- prefixes all static member accesses with the classes name.
              -- 'qualifyStaticMembers',
              -- converts string concatenaton to Text Blocks.
              "stringConcatToTextBlock",
              -- converts a switch statement to a switch expression.
              "switchExpression",
              -- simplifies the finally block to using a try-with-resource statement.
              "tryWithResource",
            },
          },
          configuration = {
            --updateBuildConfiguration = 'interactive',
            runtimes = path.runtimes,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          referenceCodeLens = {
            enabled = true,
          },
          inlayHints = {
            parameterNames = {
              enabled = true, -- literals, all, none
            },
          },
          saveActions = {
            organizeImports = true,
          },
          format = {
            settings = {
              url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
              profile = "GoogleStyle",
            },
          },
          signatureHelp = {
            enabled = true,
            description = {
              enabled = true,
            },
          },
          completion = {
            favoriteStaticMembers = {
              "org.hamcrest.MatcherAssert.assertThat",
              "org.hamcrest.Matchers.*",
              "org.hamcrest.CoreMatchers.*",
              "io.crate.testing.Asserts.assertThat",
              "org.assertj.core.api.Assertions.assertThat",
              "org.assertj.core.api.Assertions.assertThatThrownBy",
              "org.assertj.core.api.Assertions.assertThatExceptionOfType",
              "org.assertj.core.api.Assertions.catchThrowable",
              "org.junit.jupiter.api.Assertions.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
              "org.mockito.Mockito.*",
            },
            filteredTypes = {},
            importOrder = {},
          },
          extendedClientCapabilities = jdtls.extendedClientCapabilities,

          contentProvider = {
            preferred = "fernflower",
          },
          references = {
            includeAccessors = true,
            includeDecompiledSources = true,
          },
          rename = {
            enabled = true,
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            useBlocks = true,
          },
        },
      }

      -- This starts a new client & server,
      -- or attaches to an existing client & server depending on the `root_dir`.
      jdtls.start_or_attach({
        cmd = cmd,
        settings = lsp_settings,
        on_attach = jdtls_on_attach,
        capabilities = cache_vars.capabilities,
        root_dir = root_dir,
        flags = {
          allow_incremental_sync = true,
        },
        init_options = {
          bundles = path.bundles,
          workspaceFolders = ws_folders_jdtls,
        },
        handlers = {
          ["language/status"] = function() end,
        },
      })
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = java_cmds,
      pattern = { "java" },
      desc = "Setup jdtls",
      callback = jdtls_setup,
    })
  end,
}
