vim.g.loaded_codewhisperer_plugin = 1
vim.g.aws_profile = "limonoct"
--vim.g.cw_debugging = true


vim.keymap.set('n', '<leader>cw', '<cmd>:CWGenerateNvim<CR>', { silent = true, desc = '[C]ode [W]hisperer' })
