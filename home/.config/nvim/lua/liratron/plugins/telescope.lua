return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope-file-browser.nvim",
    "albenisolmos/telescope-oil.nvim",
    "folke/todo-comments.nvim",
    { "nvim-telescope/telescope-frecency.nvim", version = "*" },
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
        frecency = {
          show_filter_column = false, -- Default: true
          matcher = "fuzzy",
        },
      },
      defaults = telescopeThemes.get_ivy({
        -- layout_strategy = "horizontal",
        layout_config = {
          bottom_pane = {
            height = 0.90,
            width = 1,
            prompt_position = "top",
            preview_width = 0.55,
            preview_cutoff = 120,
            horizontal = { mirror = false },
            vertical = { mirror = false },
          },
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
        file_ignore_patterns = { "node_modules", "^./.git/", ".git/", ".cache", "%.o", "%.a", "%.out", "%.class" },
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
    telescope.load_extension("dap")
    telescope.load_extension("frecency")

    -- set keymaps
    local builtin = require("telescope.builtin")

    local function telescope_buffer_dir()
      local path = vim.fn.expand("%:p:h"):match("oil://(.*)")
      if path then
        return path
      else
        return vim.fn.expand("%:p:h")
      end
    end

    vim.keymap.set("n", "<leader>s?", builtin.oldfiles, { desc = "[?] Find recently opened files" })
    vim.keymap.set("n", "<leader>sb", function()
      builtin.buffers({
        sort_mru = true,
        -- -- Sorts current and last buffer to the top and selects the lastused (default: false)
        -- -- Leave this at false, otherwise when put in normal mode, the buffer
        -- -- below is selected, not the one at the top
        sort_lastused = false,
        attach_mappings = function(prompt_bufnr, map)
          local action_state = require("telescope.actions.state")
          local bd = require("mini.bufremove").delete
          local delete_buffer = function()
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:delete_selection(function(selection)
              local bufnr = selection.bufnr
              local force = vim.api.nvim_buf_get_option(bufnr, "buftype") == "terminal"
              if force then
                return pcall(vim.api.nvim_buf_delete, bufnr, { force = force })
              elseif vim.fn.getbufvar(bufnr, "&modified") == 1 then
                local choice =
                  vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname(bufnr)), "&Yes\n&No\n&Cancel")
                if choice == 1 then -- Yes
                  vim.api.nvim_buf_call(bufnr, function()
                    vim.cmd("write")
                  end)
                  return bd(bufnr)
                elseif choice == 2 then -- No
                  return bd(bufnr, true)
                end
              else
                return bd(bufnr)
              end
            end)
          end
          map("n", "<M-d>", delete_buffer)
          map("i", "<M-d>", delete_buffer)
          return true
        end,
      })
    end, { desc = "[ ] Find existing buffers" })
    vim.keymap.set("n", "<leader>sc", builtin.current_buffer_fuzzy_find, { desc = "[S]earch  in current buffer" })

    vim.keymap.set("n", "<leader>sgf", builtin.git_files, { desc = "Search Git [F]iles" })
    vim.keymap.set("n", "<leader>sgb", builtin.git_branches, { desc = "Search [G]it [B]ranches" })
    vim.keymap.set("n", "<leader>sgs", builtin.git_status, { desc = "Search Git [S]tatus" })
    vim.keymap.set("n", "<leader>sgc", builtin.git_commits, { desc = "Search Git [C]ommits" })
    -- vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>sf", function()
      local cwd = vim.fn.getcwd()
      telescope.extensions.frecency.frecency({
        workspace = "CWD",
        cwd = cwd,
        prompt_title = "[S]earch [F]iles in " .. cwd,
      })
    end, { desc = "[S]earch [F]iles" })

    vim.keymap.set("n", "<leader>sF", function()
      -- Use Telescope's find_files with a specific cwd
      builtin.find_files({
        cwd = telescope_buffer_dir(),
        prompt_title = "Files in " .. telescope_buffer_dir(),
      })
    end, { desc = "[S]earch [F]iles in current dir" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
    vim.keymap.set("n", "<leader>sW", function()
      -- Use Telescope's find_files with a specific cwd
      builtin.grep_string({
        cwd = telescope_buffer_dir(),
        prompt_title = "Search currenty word in " .. telescope_buffer_dir(),
      })
    end, { desc = "[S]earch current [W]ord in current dir" })
    vim.keymap.set("n", "<leader>ss", builtin.live_grep, { desc = "[S]earch by [G]rep" })
    vim.keymap.set("n", "<leader>sS", function()
      builtin.live_grep({
        cwd = telescope_buffer_dir(),
        prompt_title = "Search by Grep in " .. telescope_buffer_dir(),
      })
    end, { desc = "[S]earch by [G]rep in current dir" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
    vim.keymap.set("n", "<leader>sp", builtin.spell_suggest, { desc = "[S][P]ell" })
    vim.keymap.set("n", "<leader>s,", function()
      builtin.find_files({
        cwd = vim.fn.stdpath("config"),
      })
    end, { desc = "Nvim Config" })

    -- file_browser
    vim.keymap.set("n", "<leader>sv", function()
      telescope.extensions.file_browser.file_browser({
        path = telescope_buffer_dir(),
        cwd = telescope_buffer_dir(),
        respect_gitignore = false,
        hidden = true,
        grouped = true,
        previewer = true,
        initial_mode = "normal",
        layout_config = { height = 40 },
      })
    end, { desc = "[P]roject [V]iew" })

    vim.keymap.set("n", "<leader>stt", "<cmd>TodoTelescope keywords=TODO<cr>", { desc = "[T]odo" })
        vim.keymap.set("n", "<leader>stp", "<cmd>TodoTelescope cwd=" .. vim.g.notesdir
      .. " keywords=TODO<cr>", { desc = "[T]odo for [P]lanning" })
    vim.keymap.set(
      "n",
      "<leader>sta",
      "<cmd>TodoTelescope keywords=PERF,HACK,TODO,NOTE,TEAM,FIX<cr>",
      { desc = "[T]odo ALL" }
    )

    -- Iterate through incomplete tasks in telescope
    -- rg "^\s*-\s\[ \]" test-markdown.md
    vim.keymap.set("n", "<leader>sti", function()
      builtin.grep_string({
        prompt_title = "Incomplete Tasks",
        -- search = "- \\[ \\]", -- Fixed search term for tasks
        search = "^- \\[ \\]", -- Ensure "- [ ]" is at the beginning of the line
        search_dirs = { vim.g.notesdir }, -- Restrict search to the current working directory
        use_regex = true, -- Enable regex for the search term
        initial_mode = "normal", -- Start in normal mode
        additional_args = function()
          return { "--no-ignore" } -- Include files ignored by .gitignore
        end,
      })
    end, { desc = "[P]Search for incomplete tasks" })

    vim.keymap.set("n", "<leader>stc", function()
      builtin.grep_string({
        prompt_title = "Completed Tasks",
        -- search = [[- \[x\] `done:]], -- Regex to match the text "`- [x] `done:"
        search = "^- \\[x\\] `done:", -- Matches lines starting with "- [x] `done:"
        search_dirs = { vim.g.notesdir }, -- Restrict search to the current working directory
        use_regex = true, -- Enable regex for the search term
        initial_mode = "normal", -- Start in normal mode
        additional_args = function()
          return { "--no-ignore" } -- Include files ignored by .gitignore
        end,
      })
    end, { desc = "Search for completed tasks" })

    -- OIL
    vim.keymap.set("n", "<leader>so", "<cmd>Telescope oil<CR>", { noremap = true, silent = true })

    -- LSP
    vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "[G]oto [R]eferences" })
    vim.keymap.set("n", "gTd", builtin.lsp_definitions, { desc = "[G]oto [D]efinition" })
    vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "[G]oto [I]mplementation" })
    vim.keymap.set("n", "gS", builtin.lsp_document_symbols, { desc = "[G]o to document [S]ymbols" })
    vim.keymap.set("n", "gwS", builtin.lsp_workspace_symbols, { desc = "[G]o to [W]orkspace [S]ymbols" })
    vim.keymap.set("n", "gws", builtin.lsp_dynamic_workspace_symbols, { desc = "[G]o to [W]orkspace [S]ymbols" })
    vim.keymap.set("n", "gTho", builtin.lsp_outgoing_calls, { desc = "[G]o to [H]ierarchy [I]ncoming" })
    vim.keymap.set("n", "gThi", builtin.lsp_incoming_calls, { desc = "[G]o to [H]ierarchy [O]utgoing" })
    vim.keymap.set("n", "gTt", builtin.lsp_type_definitions, { desc = "[G]oto [T]ype Definitions" })
  end,
}
