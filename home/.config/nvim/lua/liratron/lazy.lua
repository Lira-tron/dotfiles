-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({

    -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  'mbbill/undotree',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim', opts = {} },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk, { buffer = bufnr, desc = '[G]o to [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk, { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
        vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk, { buffer = bufnr, desc = '[P]review [H]unk' })
      end,
    },
  },
  {
    'rose-pine/neovim',
    as = 'rose-pine',
    config = function()

      vim.cmd('colorscheme rose-pine')
    end
  },
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },
  'nvim-treesitter/playground',

  -- theprimeagen
  'theprimeagen/refactoring.nvim',

})









--
-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.2',
    -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- history in file
  use("mbbill/undotree")
  use {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end
  }
  use("folke/zen-mode.nvim")
  use("nvim-treesitter/nvim-treesitter-context")
  use("eandrju/cellular-automaton.nvim")
  use("laytan/cloak.nvim")
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }
  -- go
  use("mfussenegger/nvim-dap")
  use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} }
  use("leoluz/nvim-dap-go")
  use 'theHamsta/nvim-dap-virtual-text'
  use 'nvim-telescope/telescope-dap.nvim'
  use 'jay-babu/mason-nvim-dap.nvim'

  -- Additional lua configuration, makes nvim stuff amazing!
  use("folke/neodev.nvim")

  -- Markdown preview
  use {"ellisonleao/glow.nvim", config = function() require("glow").setup() end}
  use ("simrat39/symbols-outline.nvim")

  -- install without yarn or npm
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

  --Language packs
  use 'sheerun/vim-polyglot'

  --File browsing
  use 'nvim-telescope/telescope-file-browser.nvim'
  use 'nvim-tree/nvim-web-devicons'

  -- Grammar checking because I can't english
  use("rhysd/vim-grammarous")

  -- Git diff
  use "sindrets/diffview.nvim"

  --todo comments
  use 'folke/todo-comments.nvim'

  -- Amazon
  use({
    "limonoct@git.amazon.com:pkg/NinjaHooks",
    branch = "mainline",
    rtp = 'configuration/vim/amazon/brazil-config',
  })

  -- For Icons to work you need to install a nerd font E.g. Hack
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons'
    }
  }

  -- Surround
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'


  -- Java Shenanigans
  use {
    'mfussenegger/nvim-jdtls',
    disable = false
  }

  use {
    "https://git.amazon.com/pkg/AmazonCodeWhispererVimPlugin",
    name = "codewhisperer",
    build = [[cat ~/.local/share/nvim/lazy/codewhisperer/service-2.json | jq '.metadata += {"serviceId":"codewhisperer"}' | tee /tmp/aws-coral-model.json && aws configure add-model --service-model file:///tmp/aws-coral-model.json --service-name codewhisperer]],
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
    },

  }

  -- OSC 52 is a terminal sequence used to copy printed text into clipboard.
  -- (copy from SSH session)
  use {
    'ojroques/vim-oscyank',
    init = function()
      vim.g.oscyank_term = 'default'
      vim.g.oscyank_silent = true
    end,
    config = function()
      vim.keymap.set({ 'v', 'x' }, '<leader>y', ':OSCYankVisual<CR>', { silent = true, desc = 'OSC yank' })
      vim.keymap.set({ 'n' }, '<leader>y', '<Plug>OSCYank', { silent = true, desc = 'OSC yank' })
    end
  }

end)

