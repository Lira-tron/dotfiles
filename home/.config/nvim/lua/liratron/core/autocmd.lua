local api = vim.api

--- Remove all trailing whitespace on save
local TrimWhiteSpaceGrp = api.nvim_create_augroup("TrimWhiteSpaceGrp", { clear = true })
api.nvim_create_autocmd("BufWritePre", {
  command = [[:%s/\s\+$//e]],
  group = TrimWhiteSpaceGrp,
})

-- don't auto comment new line
api.nvim_create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

-- wrap words "softly" (no carriage return) in mail buffer
api.nvim_create_autocmd("Filetype", {
  pattern = "mail",
  callback = function()
    vim.opt.textwidth = 0
    vim.opt.wrapmargin = 0
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.columns = 100
    vim.opt.colorcolumn = "100"
  end,
})

-- api.nvim_create_autocmd("Filetype", {
--   pattern = "java",
--   callback = function()
--     vim.opt.tabstop = 2
--     vim.opt.softtabstop = 2
--     vim.opt.shiftwidth = 2
--   end,
-- })

-- detect typst filetype
api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.typ" },
  callback = function()
    vim.api.nvim_command("set filetype=typst")
  end,
})

-- Highlight on yank
api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- go to last loc when opening a buffer
api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- windows to close with "q"
api.nvim_create_autocmd("FileType", {
  pattern = {
    "dap-float",
    "fugitive",
    "help",
    "man",
    "notify",
    "qf",
    "PlenaryTestPopup",
    "startuptime",
    "tsplayground",
    "spectre_panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

local cursorline_hide = {
  "TelescopePrompt",
  "TelescopeResults",
}
local function toggle_cursorline(types)
  for _, type in pairs(types) do
    if vim.o.filetype == type then
      vim.o.cursorline = false
      break
    else
      vim.o.cursorline = true
    end
  end
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  callback = function()
    toggle_cursorline(cursorline_hide)
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
  desc = "Show the cursorline whenever the window gain focus",
  group = vim.api.nvim_create_augroup("ShowCursorLineWhenLoseFocus", { clear = true }),
  pattern = { "*" },
  callback = function()
    vim.o.cursorline = true
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
  desc = "Hide the cursorline whenever the window loses focus",
  group = vim.api.nvim_create_augroup("HideCursorLineWhenLoseFocus", { clear = true }),
  pattern = { "*" },
  callback = function()
    vim.o.cursorline = false
  end,
})

-- -- show cursor line only in active window
-- local cursorGrp = api.nvim_create_augroup("CursorLine", { clear = true })
-- api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
--   pattern = "*",
--   command = "set cursorline",
--   group = cursorGrp,
-- })
--
-- api.nvim_create_autocmd(
--   { "InsertEnter", "WinLeave" },
--   { pattern = "*", command = "set nocursorline", group = cursorGrp }
-- )

-- Enable spell checking for certain file types
api.nvim_create_autocmd(
  { "BufRead", "BufNewFile" },
  {
    pattern = { "*.txt", "*.md", "*.tex", "plaintex", "text", "gitcommit" },
    callback = function()
      vim.opt.spell = true
      vim.opt.spelllang = "en"
    end,
  }
)

-- Auto save files
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  desc = "Auto save files",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command("silent update")

      if vim.bo.filetype == "vimwiki" then
        vim.cmd(":Vimwiki2HTML")
        vim.cmd(":VimwikiRebuildTags")
      end
    end
  end,
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})
