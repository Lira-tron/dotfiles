return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "albenisolmos/telescope-oil.nvim",
    {
      "danielfalk/smart-open.nvim",
      branch = "0.2.x",
      dependencies = {
        "kkharji/sqlite.lua",
      },
    },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local telescopeThemes = require("telescope.themes")
    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"                                 -- the default case_mode is "smart_case"
        },
        ["ui-select"] = {
          telescopeThemes.get_ivy({}),
        },
      },
      defaults = telescopeThemes.get_ivy({
        -- layout_strategy = "horizontal",
        layout_config = {
          height = 0.90,
          width = 1,
          prompt_position = "top",
          preview_width = 0.55,
          preview_cutoff = 120,
          horizontal = { mirror = false },
          vertical = { mirror = false },
        },
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
      }),
      pickers = {
        -- live_grep = {
        --   layout_config = {
        --     width = 0.95,
        --   },
        -- },
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
    telescope.load_extension("smart_open")

    -- set keymaps
    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>s?", builtin.oldfiles, { desc = "[?] Find recently opened files" })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[ ] Find existing buffers" })
    vim.keymap.set("n", "<leader>sc", builtin.current_buffer_fuzzy_find, { desc = "[S]earch  in current buffer" })

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
    vim.keymap.set("n", "<leader>s,", function()
      builtin.find_files({
        cwd = vim.fn.stdpath("config"),
      })
    end, { desc = "Nvim Config" })

    local function telescope_buffer_dir()
      return vim.fn.expand("%:p:h")
    end

    -- file_browser
    vim.keymap.set("n", "<leader>sv", function()
      telescope.extensions.file_browser.file_browser({
        path = telescope_buffer_dir():match("oil:///(.*)"),
        cwd = telescope_buffer_dir(),
        respect_gitignore = false,
        hidden = true,
        grouped = true,
        previewer = true,
        initial_mode = "normal",
        layout_config = { height = 40 },
      })
    end, { desc = "[P]roject [V]iew" })

    -- OIL
    vim.keymap.set("n", "<leader>so", "<cmd>Telescope oil<CR>", { noremap = true, silent = true })

    -- Smart open
    vim.keymap.set("n", "<leader>sa", function()
      telescope.extensions.smart_open.smart_open()
    end, { noremap = true, silent = true })

    -- LSP
    vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "[G]oto [R]eferences" })
    vim.keymap.set("n", "gTd", builtin.lsp_definitions, { desc = "[G]oto [D]efinition" })
    vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "[G]oto [I]mplementation" })
    vim.keymap.set("n", "gs", builtin.lsp_document_symbols, { desc = "[G]o to document [S]ymbols" })
    vim.keymap.set("n", "gwS", builtin.lsp_workspace_symbols, { desc = "[G]o to [W]orkspace [S]ymbols" })
    vim.keymap.set("n", "gws", builtin.lsp_dynamic_workspace_symbols, { desc = "[G]o to [W]orkspace [S]ymbols" })
    vim.keymap.set("n", "gTho", builtin.lsp_outgoing_calls, { desc = "[G]o to [H]ierarchy [I]ncoming" })
    vim.keymap.set("n", "gThi", builtin.lsp_incoming_calls, { desc = "[G]o to [H]ierarchy [O]utgoing" })
    vim.keymap.set("n", "gTt", builtin.lsp_type_definitions, { desc = "[G]oto [T]ype Definitions" })
  end,
}
