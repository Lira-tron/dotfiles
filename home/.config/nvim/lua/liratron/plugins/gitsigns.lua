return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },
    -- See `:help gitsigns.txt`
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      vim.keymap.set("n", "<leader>gh", gs.preview_hunk, { buffer = bufnr, desc = "[G]it [H]unk preview" })

      vim.keymap.set({ "n", "v" }, "gnh", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
      vim.keymap.set({ "n", "v" }, "gph", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })

      vim.keymap.set("n", "<leader>gB", function()
        gs.blame_line({ full = true })
      end)
    end,
    current_line_blame = true,
  },
}
