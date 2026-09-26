local function copy_comments()
  local comments = require("nvim-agent-comments")
  local review, err = require("nvim-agent-comments.cli").collect({
    bufnr = 0,
    store_name = comments.config.store_name,
  })
  if not review then
    return vim.notify(err, vim.log.levels.ERROR)
  end
  if #review.comments == 0 then
    return vim.notify("No project comments to copy")
  end

  local function git(args, fallback)
    local command = { "git", "-C", review.root }
    vim.list_extend(command, args)
    local result = vim.system(command, { text = true }):wait()
    return result.code == 0 and vim.trim(result.stdout) or fallback
  end

  local project = vim.fn.fnamemodify(review.root, ":t")
  local branch = git({ "symbolic-ref", "--quiet", "--short", "HEAD" }, "HEAD")
  local commit = git({ "rev-parse", "--short", "HEAD" }, "unavailable")
  local lines = {
    ("## Session: pkg/%s@%s/working-tree"):format(project, branch),
    "",
    "I reviewed your code and have the following comments. Please address them.",
    "",
    "Reviewing working tree (HEAD: " .. commit .. ")",
    "",
    "Comment types: COMMENT (General feedback), ISSUE (Problem to fix)",
    "",
    "## Local Neovim Comments",
    "",
  }
  for index, comment in ipairs(review.comments) do
    local first = comment.resolved_start_line or comment.start_line
    local last = comment.resolved_end_line or comment.end_line
    local location = comment.path .. ":" .. first
    if last ~= first then
      location = location .. "-" .. last
    end
    local stale = comment.status == "stale" and " [stale location]" or ""
    local body = comment.body:gsub("\r\n", "\n"):gsub("\n", "\n   ")
    lines[#lines + 1] = ("%d. **[%s]** `%s`%s - %s"):format(
      index,
      (comment.type or "comment"):upper(),
      location,
      stale,
      body
    )
    lines[#lines + 1] = ""
  end

  local text = table.concat(lines, "\n")
  local copied
  if vim.fn.has("clipboard") == 1 then
    copied = vim.fn.setreg("+", text) == 0
  else
    -- Use the existing terminal clipboard integration for remote sessions.
    copied = vim.fn.OSCYank(text) == 1
  end
  if not copied then
    return vim.notify("Could not copy project comments", vim.log.levels.ERROR)
  end
  vim.notify(("Copied %d comments for your agent"):format(#review.comments))
end

local function clear_comments()
  local comments = require("nvim-agent-comments")
  local root = require("nvim-agent-comments.root")
  local store = require("nvim-agent-comments.store")
  local project, err = root.from_buffer(0)
  if not project then
    return vim.notify(err, vim.log.levels.ERROR)
  end
  local path, path_err = root.store_path(project, comments.config.store_name)
  if not path then
    return vim.notify(path_err, vim.log.levels.ERROR)
  end
  local signature = store.signature(path)
  local saved, load_err = store.load(path)
  if not saved then
    return vim.notify(load_err, vim.log.levels.ERROR)
  end
  if #saved.comments == 0 then
    return vim.notify("No project comments to clear")
  end
  local answer = vim.fn.confirm(
    ("Delete all %d project comments and their replies?"):format(#saved.comments),
    "&Yes\n&No",
    2
  )
  if answer ~= 1 then
    return
  end
  local ok, save_err = store.save(path, store.empty(), signature)
  if not ok then
    return vim.notify(save_err, vim.log.levels.ERROR)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      comments.render(buf)
    end
  end
  vim.notify("Cleared all comments in " .. project)
end

return {
  dir = "/workplace/limonoct/nvim-agent-comments",
  enabled = not vim.g.vscode,
  lazy = false,
  init = function()
    -- Configure once below, preserving LazyVim's [q / ]q quickfix mappings.
    vim.g.loaded_nvim_agent_comments = true
  end,
  opts = { navigation = false },
  config = function(_, opts)
    require("nvim-agent-comments").setup(opts)
    local function apply_theme()
      local highlights = {
        CommentBackdrop = "Normal",
        CommentBoxActiveBorder = "FloatBorder",
        CommentBoxStaleBorder = "DiagnosticError",
        CommentBoxText = "NormalFloat",
        CommentBoxTitle = "FloatTitle",
        CommentBoxHint = "Comment",
        CommentBoxSaved = "DiagnosticOk",
        CommentBoxStale = "DiagnosticError",
        CommentReplyBorder = "DiagnosticOk",
        CommentReplyText = "DiagnosticOk",
        CommentPicker = "NormalFloat",
        CommentPickerSelected = "PmenuSel",
      }
      for name, target in pairs(highlights) do
        vim.api.nvim_set_hl(0, name, { link = target })
      end
    end
    apply_theme()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup(
        "AgentCommentsTheme",
        { clear = true }
      ),
      callback = apply_theme,
    })
  end,
  keys = {
    {
      "<leader>ac",
      "<cmd>NvimAgentCommentsAdd<cr>",
      desc = "Add agent comment",
    },
    {
      "<leader>ac",
      ":NvimAgentCommentsAddVisual<cr>",
      mode = "x",
      desc = "Add agent comment to selection",
    },
    {
      "<leader>ae",
      "<cmd>NvimAgentCommentsEdit<cr>",
      desc = "Edit agent comment",
    },
    {
      "<leader>ad",
      "<cmd>NvimAgentCommentsDelete<cr>",
      desc = "Delete agent comment",
    },
    {
      "<leader>aj",
      "<cmd>NvimAgentCommentsJump<cr>",
      desc = "Jump to comment anchor",
    },
    {
      "<leader>as",
      "<cmd>NvimAgentCommentsList<cr>",
      desc = "Search project comments",
    },
    {
      "<leader>ah",
      "<cmd>NvimAgentCommentsToggle<cr>",
      desc = "Show/hide agent comments",
    },
    {
      "<leader>an",
      "<cmd>NvimAgentCommentsNext<cr>",
      desc = "Next agent comment",
    },
    {
      "<leader>ap",
      "<cmd>NvimAgentCommentsPrev<cr>",
      desc = "Previous agent comment",
    },
    {
      "<leader>ar",
      "<cmd>NvimAgentCommentsReanchor<cr>",
      desc = "Reanchor agent comment",
    },
    {
      "<leader>ar",
      ":NvimAgentCommentsReanchor<cr>",
      mode = "x",
      desc = "Reanchor comment to selection",
    },
    {
      "<leader>at",
      copy_comments,
      desc = "Copy comments for agent",
    },
    {
      "<leader>aq",
      clear_comments,
      desc = "Clear all project comments",
    },
  },
}
