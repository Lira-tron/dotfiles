return {
  "olimorris/codecompanion.nvim",
  config = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>ac", ":CodeCompanionChat<CR>", desc = "Copilot toggle" },
  }
}

-- return {
--   {
--     "olimorris/codecompanion.nvim",
--     dependencies = {
--       "nvim-lua/plenary.nvim",
--       "nvim-treesitter/nvim-treesitter",
--       "nvim-telescope/telescope.nvim", -- Optional
--       {
--         "stevearc/dressing.nvim", -- Optional: Improves the default Neovim UI
--         opts = {},
--       },
--     },
--     keys = {
--       { "<leader>cia", "<CMD>CodeCompanionAction<CR>", { desc = "CodeCompanionAction" } },
--       { "<leader>cip", "<CMD>CodeCompanion<CR>", { desc = "CodeCompanion" } },
--       { "<leader>cic", "<CMD>CodeCompanionChat<CR>", { desc = "CodeCompanionChat" } },
--     },
--     opts = {
--       strategies = {
--         chat = {
--           adapter = "gemini",
--         },
--         inline = {
--           adapter = "gemini",
--         },
--         agent = {
--           adapter = "gemini",
--         },
--         adapters = {
--           gemini = function()
--             return require("codecompanion.adapters").extend("gemini", {})
--           end,
--         },
--       },
--     },
--     config = function(_, opts)
--       require("codecompanion").setup(opts)
--       local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
--
--       vim.api.nvim_create_autocmd({ "User" }, {
--         pattern = "CodeCompanionInline*",
--         group = group,
--         callback = function(request)
--           if request.match == "CodeCompanionInlineFinished" then
--             -- Format the buffer after the inline request has completed
--             require("conform").format { bufnr = request.buf }
--           end
--         end,
--       })
--     end,
--   },
-- }
