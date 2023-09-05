--
-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.2',
    -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use({
    'rose-pine/neovim',
    as = 'rose-pine',
    config = function()

      vim.cmd('colorscheme rose-pine')
    end
  })

  --Treesitter
  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use("nvim-treesitter/playground")
  -- theprimeagen
  use("theprimeagen/refactoring.nvim")
  -- history in file
  use("mbbill/undotree")
  use("tpope/vim-fugitive")
  use("tpope/vim-rhubarb")
  -- LSP
  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    requires = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      {'rafamadriz/friendly-snippets'},
    }
  }
  use {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end
  }
  use("lewis6991/gitsigns.nvim")
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

  -- Go tests
  use 'buoto/gotests-vim'

  -- Java Shenanigans
  use {
    'mfussenegger/nvim-jdtls',
    disable = false
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

