return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" },
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "albenisolmos/telescope-oil.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"                                 -- the default case_mode is "smart_case"
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },

      },
      layout_config = {
        width = 0.80,
        prompt_position = "top",
        preview_cutoff = 120,
        horizontal = { mirror = false },
        vertical = { mirror = false },
      },
      layout_strategy = "horizontal",
      defaults = {
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--iglob",
          "!package-lock.json",
        },
        mappings = {
          i = {
            ["<C-y>"] = actions.select_default,
            ["<C-k>"] = actions.which_key,
          },
          n = {
            ["<C-c>"] = actions.close,
            ["<C-y>"] = actions.select_default,
            ["<C-k>"] = actions.which_key,
          },
        },
        path_display = { "smart" },
        -- path_display = { "truncate " },
        -- path_display = {
        --   shorten = {
        --     len = 1,
        --     exclude = { 1, -1 },
        --   },
        -- },
        sorting_strategy = "ascending",
        file_ignore_patterns = { "node_modules", "^./.git/" },
      },
      pickers = {
        live_grep = {
          layout_config = {
            width = 0.95,
          },
        },
        find_files = {
          hidden = true,
          follow = true,
        },
      },
    })

    telescope.load_extension("file_browser")
    telescope.load_extension("fzf")
    telescope.load_extension("oil")
    telescope.load_extension("ui-select")

    -- set keymaps
    local builtin = require("telescope.builtin")
    local telescopeThemes = require("telescope.themes")

    vim.keymap.set("n", "<leader>s?", builtin.oldfiles, { desc = "[?] Find recently opened files" })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[ ] Find existing buffers" })
    vim.keymap.set("n", "<leader>sc", function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      builtin.current_buffer_fuzzy_find(telescopeThemes.get_dropdown({
        winblend = 10,
        previewer = false,
      }))
    end, { desc = "[S]earch  in current buffer" })

    vim.keymap.set("n", "<leader>sgf", builtin.git_files, { desc = "Search Git [F]iles" })
    vim.keymap.set("n", "<leader>sgb", builtin.git_branches, { desc = "Search [G]it [B]ranches" })
    vim.keymap.set("n", "<leader>sgs", builtin.git_status, { desc = "Search Git [S]tatus" })
    vim.keymap.set("n", "<leader>sgc", builtin.git_commits, { desc = "Search Git [C]ommits" })
    vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
    vim.keymap.set("n", "<leader>ss", builtin.live_grep, { desc = "[S]earch by [G]rep" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
    vim.keymap.set("n", "<leader>sp", builtin.spell_suggest, { desc = "[S][P]ell" })

    local function telescope_buffer_dir()
      return vim.fn.expand("%:p:h")
    end

    -- file_browser
    vim.keymap.set("n", "<leader>sv", function()
      telescope.extensions.file_browser.file_browser(
        {
          path = telescope_buffer_dir():match("oil:///(.*)"),
          cwd = telescope_buffer_dir(),
          respect_gitignore = false,
          hidden = true,
          grouped = true,
          previewer = true,
          initial_mode = "normal",
          layout_config = { height = 40 },
        }
      )
    end, { desc = "[P]roject [V]iew" })

    -- OIL
    vim.keymap.set("n", "<leader>so", "<cmd>Telescope oil<CR>", { noremap = true, silent = true })

    -- LSP
    vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "[G]oto [R]eferences" })
    vim.keymap.set("n", "gtd", builtin.lsp_definitions, { desc = "[G]oto [D]efinition" })
    vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "[G]oto [I]mplementation" })
    vim.keymap.set("n", "gs", builtin.lsp_document_symbols, { desc = "[G]o to document [S]ymbols" })
    vim.keymap.set("n", "gws", builtin.lsp_workspace_symbols, { desc = "[G]o to [W]orkspace [S]ymbols" })
    vim.keymap.set("n", "gtho", builtin.lsp_outgoing_calls, { desc = "[G]o to [H]ierarchy [I]ncoming" })
    vim.keymap.set("n", "gthi", builtin.lsp_incoming_calls, { desc = "[G]o to [H]ierarchy [O]utgoing" })
    vim.keymap.set("n", "gt", builtin.lsp_type_definitions, { desc = "[G]oto [T]ype Definitions" })
  end,
}
