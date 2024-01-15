return {
  "rcarriga/nvim-notify",

  config = function()
    vim.opt.termguicolors = true
    vim.notify = require("notify")
    local notify = require("notify")

    notify.setup({
      minimum_width = 50,
      background_colour = "#1d2021",
      stages = "fade",
      timeout = 2000,
      fps = 60,
    })

    vim.keymap.set("n", "<leader>sn", function()
      require("telescope").extensions.notify.notify()
    end, { desc = "[S]earch [N]otification" })
  end,
}

-- return {
--   "folke/noice.nvim",
--   event = "VeryLazy",
--   opts = {
--     -- add any options here
--   },
--   dependencies = {
--     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
--     "MunifTanjim/nui.nvim",
--     -- OPTIONAL:
--     --   `nvim-notify` is only needed, if you want to use the notification view.
--     --   If not available, we use `mini` as the fallback
--     "rcarriga/nvim-notify",
--     },
--      keys = {
--     { "<leader>sn", function() require("telescope").load_extension("noice") end, desc = "[S]earch [N]otifications" },
--     }
-- }

-- return {
--
--   "rcarriga/nvim-notify",
--
--   config = function()
--     vim.opt.termguicolors = true
--     vim.notify = require("notify")
--     local notify = require("notify")
--
--     notify.setup({
--       minimum_width = 50,
--       background_colour = "#1d2021",
--       stages = "fade",
--       timeout = 2000,
--       fps = 60,
--     })
--   end,
-- }
