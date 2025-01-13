return {
  {
    "arnamak/stay-centered.nvim",
    opts = function()
      require("stay-centered").setup({
        -- Add any configurations here, like skip_filetypes if needed
        -- skip_filetypes = {"lua", "typescript"},
      })
      vim.keymap.set("n", "<leader>ST", function()
        require("stay-centered").toggle()
        vim.notify("Toggled stay-centered", vim.log.levels.INFO)
      end, { desc = "[P]Toggle stay-centered.nvim" })
    end,
  },
}
