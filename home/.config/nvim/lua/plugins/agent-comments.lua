local function copy_text(text)
  if vim.fn.has("clipboard") == 1 then
    return vim.fn.setreg("+", text) == 0
  end
  -- Use the existing terminal clipboard integration for remote sessions.
  return vim.fn.OSCYank(text) == 1
end

local function copy_open_threads()
  local thread_path = require("nvim-agent-comments.thread").target(0)
  local root = require("nvim-agent-comments.root")
  local project, err = root.find(thread_path or vim.api.nvim_buf_get_name(0))
  if not project then
    return vim.notify(err, vim.log.levels.ERROR)
  end
  local path, path_err = thread_path, nil
  if not path then
    path, path_err = root.store_path(
      project, require("nvim-agent-comments").config.store_name
    )
  end
  if not path then
    return vim.notify(path_err, vim.log.levels.ERROR)
  end
  local saved, load_err = require("nvim-agent-comments.store").load(path)
  if not saved then
    return vim.notify(load_err, vim.log.levels.ERROR)
  end
  local references = {}
  for _, comment in ipairs(saved.comments) do
    if comment.state ~= "done" then
      references[#references + 1] = comment.thread_number
          and ("#%d"):format(comment.thread_number)
        or ("ID `%s`"):format(comment.id)
    end
  end
  if #references == 0 then
    return vim.notify("No open threads to copy")
  end
  local text = ("Read Neovim comment threads %s in `%s`. ")
    :format(table.concat(references, ", "), path)
    .. "Read each thread's full conversation and address my latest unanswered "
    .. "message in each. Skip DONE threads."
  if not copy_text(text) then
    return vim.notify("Could not copy thread references", vim.log.levels.ERROR)
  end
  vim.notify(("Copied %d open thread references for your agent"):format(#references))
end

local function copy_current_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local thread_path, thread_id = require("nvim-agent-comments.thread").target(bufnr)
  local root = require("nvim-agent-comments.root")
  local project, err = root.find(thread_path or vim.api.nvim_buf_get_name(bufnr))
  if not project then
    return vim.notify(err, vim.log.levels.ERROR)
  end
  local path, path_err = thread_path, nil
  if not path then
    path, path_err = root.store_path(
      project, require("nvim-agent-comments").config.store_name
    )
  end
  if not path then
    return vim.notify(path_err, vim.log.levels.ERROR)
  end
  local saved, load_err = require("nvim-agent-comments.store").load(path)
  if not saved then
    return vim.notify(load_err, vim.log.levels.ERROR)
  end
  local relative = root.relative(project, vim.api.nvim_buf_get_name(bufnr))
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local candidates = vim.tbl_filter(function(comment)
    if thread_id then
      return comment.id == thread_id
    end
    if comment.path ~= relative then
      return false
    end
    local resolved = require("nvim-agent-comments.anchors").resolve(lines, comment)
    return cursor >= (resolved.start_line or comment.start_line)
      and cursor <= (resolved.end_line or comment.end_line)
  end, saved.comments)
  if #candidates == 0 then
    return vim.notify("No comment on the current line")
  end
  local function copy(comment)
    if not comment then
      return
    end
    local reference = comment.thread_number
        and ("thread #%d"):format(comment.thread_number)
      or ("with ID `%s`"):format(comment.id)
    local text = ("Read Neovim comment %s in `%s`. "
      .. "Read the full conversation and address my latest unanswered message.")
      :format(reference, path)
    if not copy_text(text) then
      return vim.notify("Could not copy thread reference", vim.log.levels.ERROR)
    end
    vim.notify("Copied thread reference for your agent")
  end
  if #candidates == 1 then
    return copy(candidates[1])
  end
  vim.ui.select(candidates, {
    prompt = "Copy comment thread",
    format_item = function(comment)
      return (comment.thread_number and ("#%d "):format(comment.thread_number) or "") .. comment.body
    end,
  }, copy)
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
  local cleared = store.empty()
  cleared.next_thread_number = saved.next_thread_number
  local ok, save_err = store.save(path, cleared, signature)
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
        CommentBoxStaleBorder = "CommentBoxStale",
        CommentBoxText = "NormalFloat",
        CommentBoxTitle = "FloatTitle",
        CommentBoxHint = "Comment",
        CommentBoxSaved = "DiagnosticOk",
        CommentBoxDone = "DiagnosticOk",
        CommentReplyBorder = "CommentReplyText",
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
      "<leader>ai",
      "<cmd>NvimAgentCommentsEdit<cr>",
      desc = "Edit latest message or reply",
    },
    {
      "<leader>ae",
      "<cmd>NvimAgentCommentsThread<cr>",
      desc = "Open agent comment thread",
    },
    {
      "<leader>at",
      "<cmd>NvimAgentCommentsDone<cr>",
      desc = "Toggle thread DONE",
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
      "<leader>aha",
      "<cmd>NvimAgentCommentsToggle<cr>",
      desc = "Show/hide all agent comments",
    },
    {
      "<leader>ahg",
      "<cmd>NvimAgentCommentsToggle done<cr>",
      desc = "Show/hide DONE threads",
    },
    {
      "<leader>ahi",
      "<cmd>NvimAgentCommentsToggle issue<cr>",
      desc = "Show/hide Issue threads",
    },
    {
      "<leader>ahc",
      "<cmd>NvimAgentCommentsToggle comment<cr>",
      desc = "Show/hide Comment threads",
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
      "<leader>ag",
      copy_current_comment,
      desc = "Copy thread reference for agent",
    },
    {
      "<leader>aG",
      copy_open_threads,
      desc = "Copy all open thread references for agent",
    },
    {
      "<leader>aq",
      clear_comments,
      desc = "Clear all project comments",
    },
  },
}
