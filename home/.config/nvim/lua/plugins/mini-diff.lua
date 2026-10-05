local function update_preview(preview, buf, data)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  local label = vim.b[buf].minidiff_base_label or "Default"
  vim.api.nvim_buf_set_name(
    preview,
    "diff-baseline://" .. preview .. "/" .. label .. "/" .. filename
  )
  vim.bo[preview].readonly = false
  vim.bo[preview].modifiable = true
  vim.api.nvim_buf_set_lines(
    preview,
    0,
    -1,
    false,
    vim.split(data.ref_text:gsub("\n$", ""), "\n", { plain = true })
  )
  vim.bo[preview].modified = false
  vim.bo[preview].modifiable = false
  vim.bo[preview].readonly = true
  vim.b[preview].minidiff_preview_ref = data.ref_text
  vim.b[preview].minidiff_preview_label = label
end

local function toggle_baseline(vertical)
  local original = vim.b.minidiff_original
  if original then
    if original.vertical then
      vim.api.nvim_win_close(0, true)
      return
    end
    if not vim.api.nvim_buf_is_valid(original.buf) then
      vim.notify("Original buffer is no longer available", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_win_set_buf(0, original.buf)
    vim.fn.winrestview(original.view)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local data = require("mini.diff").get_buf_data(buf)
  if not data or data.ref_text == nil then
    vim.notify(
      "No diff baseline available for this buffer",
      vim.log.levels.WARN
    )
    return
  end

  local view = vim.fn.winsaveview()
  local preview = vim.api.nvim_create_buf(false, true)
  update_preview(preview, buf, data)
  vim.b[preview].minidiff_original =
    { buf = buf, view = view, vertical = vertical }
  vim.bo[preview].bufhidden = "wipe"
  vim.bo[preview].filetype = vim.bo[buf].filetype
  vim.keymap.set("n", "q", "<leader>gU", {
    buffer = preview,
    remap = true,
    desc = "Close Diff Baseline",
  })
  if vertical then
    vim.cmd.vsplit()
  end
  vim.api.nvim_win_set_buf(0, preview)
  vim.fn.winrestview(view)
end

return {
  "nvim-mini/mini.diff",
  keys = {
    {
      "<leader>gC",
      function()
        require("config.diff-scope").pick()
      end,
      desc = "Choose Diff Scope",
    },
    {
      "<leader>gu",
      function()
        toggle_baseline(true)
      end,
      desc = "Diff Baseline File (Vertical Split)",
    },
    {
      "<leader>gU",
      function()
        toggle_baseline(false)
      end,
      desc = "Toggle Diff Baseline File",
    },
    {
      "<leader>gn",
      function()
        require("mini.diff").goto_hunk("next")
      end,
      desc = "Next Diff Hunk",
    },
    {
      "<leader>gp",
      function()
        require("mini.diff").goto_hunk("prev")
      end,
      desc = "Previous Diff Hunk",
    },
    { "gng", "<leader>gn", remap = true, desc = "Next Diff Hunk" },
    { "gpg", "<leader>gp", remap = true, desc = "Previous Diff Hunk" },
  },
  opts = function(_, opts)
    opts.source = require("config.diff-scope").source()
    -- These hunks include commits: keep staging/resetting in the Git client.
    opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
      apply = "",
      reset = "",
    })

    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("MiniDiffPreview", { clear = true }),
      pattern = "MiniDiffUpdated",
      callback = function(event)
        local data = require("mini.diff").get_buf_data(event.buf)
        if not data or data.ref_text == nil then
          return
        end
        for _, preview in ipairs(vim.api.nvim_list_bufs()) do
          local original = vim.b[preview].minidiff_original
          if
            original
            and original.buf == event.buf
            and (
              vim.b[preview].minidiff_preview_ref ~= data.ref_text
              or vim.b[preview].minidiff_preview_label
                ~= vim.b[event.buf].minidiff_base_label
            )
          then
            update_preview(preview, event.buf, data)
          end
        end
      end,
    })
  end,
}
