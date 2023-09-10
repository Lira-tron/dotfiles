return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({

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
                        ['<C-y>'] = actions.select_default,
                        ['<C-h>'] = actions.which_key,
                    },
                    n = {
                        ['<C-c>'] = actions.close,
                        ['<C-y>'] = actions.select_default,
                        ['<C-h>'] = actions.which_key,
                    }
                },
                path_display = { "truncate " },
                -- path_display = {
                --   shorten = {
                --     len = 1,
                --     exclude = { 1, -1 }
                --   }
                -- },
                pickers = {
                    live_grep = {
                        layout_config = {
                            width = 0.95,
                        },
                    },
                    find_files = {
                        hidden = true,
                        follow = true
                    }
                }
            }
        })

        telescope.load_extension("fzf")
        telescope.load_extension('file_browser')
        -- set keymaps
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
        vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
        vim.keymap.set('n', '<leader>sc', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
            })
        end, { desc = '[S]earch  in [C]urrent buffer' })

        vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
        vim.keymap.set('n', '<leader>pv', ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
            { noremap = true }, { desc = '[P]roject [V]iew' })

        vim.keymap.set('n', '<leader>sG', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = '[S]earch [G]rep >' })
        vim.keymap.set('n', '<leader>sp', builtin.spell_suggest, { desc = '[S][P]ell' })
    end,
}
