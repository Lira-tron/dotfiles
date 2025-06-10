--Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v" }, "gn", "<nop>")
vim.keymap.set({ "n", "v" }, "gN", "<nop>")

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "C-d keep cursor in middle" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "C-u keep cursor in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "search keep cursor in middle" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "search keep cursor in middle" })


-- Resize window using <ctrl> arrow keys
vim.keymap.set("n", "<C-M-k>", "<cmd>resize +5<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-M-j>", "<cmd>resize -5<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-M-h>", "<cmd>vertical resize -5<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-M-l>", "<cmd>vertical resize +5<cr>", { desc = "Increase Window Width" })

vim.keymap.set(
  "n",
  "gpb",
  "<cmd>bprevious<cr>",
  { desc = "[G]o [P]rev [B]uffer" }
)
vim.keymap.set("n", "gnb", "<cmd>bnext<cr>", { desc = "[G]o [N]ext [B]uffer" })

local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

vim.keymap.set("n", "gnd", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "gpd", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set(
  "n",
  "gne",
  diagnostic_goto(true, "ERROR"),
  { desc = "Next Error" }
)
vim.keymap.set(
  "n",
  "gpe",
  diagnostic_goto(false, "ERROR"),
  { desc = "Prev Error" }
)
vim.keymap.set(
  "n",
  "gnw",
  diagnostic_goto(true, "WARN"),
  { desc = "Next Warning" }
)
vim.keymap.set(
  "n",
  "gpw",
  diagnostic_goto(false, "WARN"),
  { desc = "Prev Warning" }
)

-- Markdown

-- In visual mode, delete all newlines within selected text
vim.keymap.set("v", "<leader>md", ":g/^\\s*$/d<CR>:nohlsearch<CR>",
  { desc = "[W][I]ki [D]elete newlines in selected text (join)" })

-- Detect todos and toggle between ":" and ";", or show a message if not found
-- This is to "mark them as done"
vim.keymap.set("n", "<leader>mT", function()
  -- Get the current line
  local current_line = vim.fn.getline(".")
  -- Get the current line number
  local line_number = vim.fn.line(".")
  if string.find(current_line, "TODO:") then
    -- Replace the first occurrence of ":" with ";"
    local new_line = current_line:gsub("TODO:", "TODO;")
    -- Set the modified line
    vim.fn.setline(line_number, new_line)
  elseif string.find(current_line, "TODO;") then
    -- Replace the first occurrence of ";" with ":"
    local new_line = current_line:gsub("TODO;", "TODO:")
    -- Set the modified line
    vim.fn.setline(line_number, new_line)
  else
    vim.cmd("echo 'todo item not detected'")
  end
end, { desc = "TODO toggle item done or not" })

-- Generate/update a Markdown TOC
-- And the markdown-toc plugin installed in Mason
local function update_markdown_toc(heading2)
  local path = vim.fn.expand("%") -- Expands the current file name to a full path
  local bufnr = 0                 -- The current buffer number, 0 references the current active buffer
  -- Save the current view
  -- If I don't do this, my folds are lost when I run this keymap
  vim.cmd("mkview")
  -- Retrieves all lines from the current buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local toc_exists = false  -- Flag to check if TOC marker exists
  local frontmatter_end = 0 -- To store the end line number of frontmatter
  -- Check for frontmatter and TOC marker
  for i, line in ipairs(lines) do
    if i == 1 and line:match("^---$") then
      -- Frontmatter start detected, now find the end
      for j = i + 1, #lines do
        if lines[j]:match("^---$") then
          frontmatter_end = j
          break
        end
      end
    end
    -- Checks for the TOC marker
    if line:match("^%s*<!%-%-%s*toc%s*%-%->%s*$") then
      toc_exists = true
      break
    end
  end
  -- Inserts H2 and H3 headings and <!-- toc --> at the appropriate position
  if not toc_exists then
    local insertion_line = 0 -- Default insertion point after first line
    if frontmatter_end > 0 then
      -- Find H1 after frontmatter
      for i = frontmatter_end + 1, #lines do
        if lines[i]:match("^#%s+") then
          insertion_line = i + 1
          break
        end
      end
    else
      -- Find H1 from the beginning
      for i, line in ipairs(lines) do
        if line:match("^#%s+") then
          insertion_line = i + 1
          break
        end
      end
    end
    -- Insert the specified headings and <!-- toc --> without blank lines
    -- Insert the TOC inside a H2 below H1
    vim.api.nvim_buf_set_lines(
      bufnr,
      insertion_line,
      insertion_line,
      false,
      { heading2, "<!-- toc -->" }
    )
  end
  -- Silently save the file, in case TOC is being created for the first time
  vim.cmd("silent write")
  -- Silently run markdown-toc to update the TOC without displaying command output
  -- vim.fn.system("markdown-toc -i " .. path)
  -- I want my bulletpoints to be created only as "-" so passing that option as
  -- an argument according to the docs
  -- https://github.com/jonschlinkert/markdown-toc?tab=readme-ov-file#optionsbullets
  vim.fn.system('markdown-toc --bullets "-" -i ' .. path)
  vim.cmd("edit!")        -- Reloads the file to reflect the changes made by markdown-toc
  vim.cmd("silent write") -- Silently save the file
  vim.notify("TOC updated and file saved", vim.log.levels.INFO)
  vim.cmd("loadview")
end

-- Keymap for English TOC
vim.keymap.set("n", "<leader>mC", function()
  update_markdown_toc("## Contents")
end, { desc = "Insert/update [M]arkdown TOC [C]ontents  (English)" })

vim.keymap.set({ "n", "v" }, "gpw", function()
  -- `?` - Start a search backwards from the current cursor position.
  -- `^` - Match the beginning of a line.
  -- `##` - Match 2 ## symbols
  -- `\\+` - Match one or more occurrences of prev element (#)
  -- `\\s` - Match exactly one whitespace character following the hashes
  -- `.*` - Match any characters (except newline) following the space
  -- `$` - Match extends to end of line
  vim.cmd("silent! ?^##\\+\\s.*$")
  -- Clear the search highlight
  vim.cmd("nohlsearch")
end, { desc = "[P]Go to previous markdown header" })

-- Search DOWN for a markdown header
-- Make sure to follow proper markdown convention, and you have a single H1
vim.keymap.set({ "n", "v" }, "gnw", function()
  vim.cmd("silent! /^##\\+\\s.*$")
  vim.cmd("nohlsearch")
end, { desc = "[P]Go to next markdown header" })

-- Toggle bullet point at the beginning of the current line in normal mode
-- If in a multiline paragraph, make sure the cursor is on the line at the top
-- "d" is for "dash"
vim.keymap.set("n", "<leader>mb", function()
  -- Get the current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_buffer = vim.api.nvim_get_current_buf()
  local start_row = cursor_pos[1] - 1
  local col = cursor_pos[2]
  -- Get the current line
  local line = vim.api.nvim_buf_get_lines(
    current_buffer,
    start_row,
    start_row + 1,
    false
  )[1]
  -- Check if the line already starts with a bullet point
  if line:match("^%s*%-") then
    -- Remove the bullet point from the start of the line
    line = line:gsub("^%s*%-", "")
    vim.api.nvim_buf_set_lines(
      current_buffer,
      start_row,
      start_row + 1,
      false,
      { line }
    )
    return
  end
  -- Search for newline to the left of the cursor position
  local left_text = line:sub(1, col)
  local bullet_start = left_text:reverse():find("\n")
  if bullet_start then
    bullet_start = col - bullet_start
  end
  -- Search for newline to the right of the cursor position and in following lines
  local right_text = line:sub(col + 1)
  local bullet_end = right_text:find("\n")
  local end_row = start_row
  while
    not bullet_end
    and end_row < vim.api.nvim_buf_line_count(current_buffer) - 1
  do
    end_row = end_row + 1
    local next_line =
        vim.api.nvim_buf_get_lines(current_buffer, end_row, end_row + 1, false)[1]
    if next_line == "" then
      break
    end
    right_text = right_text .. "\n" .. next_line
    bullet_end = right_text:find("\n")
  end
  if bullet_end then
    bullet_end = col + bullet_end
  end
  -- Extract lines
  local text_lines =
      vim.api.nvim_buf_get_lines(current_buffer, start_row, end_row + 1, false)
  local text = table.concat(text_lines, "\n")
  -- Add bullet point at the start of the text
  local new_text = "- " .. text
  local new_lines = vim.split(new_text, "\n")
  -- Set new lines in buffer
  vim.api.nvim_buf_set_lines(
    current_buffer,
    start_row,
    end_row + 1,
    false,
    new_lines
  )
end, { desc = "[M]arkdown Toggle [B]ullet point (dash)" })

-- If there is no `untoggled` or `done` label on an item, mark it as done
-- and move it to the "## completed tasks" markdown heading in the same file, if
-- the heading does not exist, it will be created, if it exists, items will be
-- appended to it at the top
--
-- If an item is moved to that heading, it will be added the `done` label
vim.keymap.set("n", "<leader>mt", function()
  -- Customizable variables
  -- NOTE: Customize the completion label
  local label_done = "done:"
  -- NOTE: Customize the timestamp format
  local timestamp = os.date("%y%m%d")
  -- local timestamp = os.date("%y%m%d")
  -- NOTE: Customize the heading and its level
  local tasks_heading = "## Completed tasks"
  -- Save the view to preserve folds
  vim.cmd("mkview")
  local api = vim.api
  -- Retrieve buffer & lines
  local buf = api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor_pos[1] - 1
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local total_lines = #lines
  -- If cursor is beyond last line, do nothing
  if start_line >= total_lines then
    vim.cmd("loadview")
    return
  end
  ------------------------------------------------------------------------------
  -- (A) Move upwards to find the bullet line (if user is somewhere in the chunk)
  ------------------------------------------------------------------------------
  while start_line > 0 do
    local line_text = lines[start_line + 1]
    -- Stop if we find a blank line or a bullet line
    if line_text == "" or line_text:match("^%s*%-") then
      break
    end
    start_line = start_line - 1
  end
  -- Now we might be on a blank line or a bullet line
  if lines[start_line + 1] == "" and start_line < (total_lines - 1) then
    start_line = start_line + 1
  end
  ------------------------------------------------------------------------------
  -- (B) Validate that it's actually a task bullet, i.e. '- [ ]' or '- [x]'
  ------------------------------------------------------------------------------
  local bullet_line = lines[start_line + 1]
  if not bullet_line:match("^%s*%- %[[x ]%]") then
    -- Not a task bullet => show a message and return
    print("Not a task bullet: no action taken.")
    vim.cmd("loadview")
    return
  end
  ------------------------------------------------------------------------------
  -- 1. Identify the chunk boundaries
  ------------------------------------------------------------------------------
  local chunk_start = start_line
  local chunk_end = start_line
  while chunk_end + 1 < total_lines do
    local next_line = lines[chunk_end + 2]
    if next_line == "" or next_line:match("^%s*%-") then
      break
    end
    chunk_end = chunk_end + 1
  end
  -- Collect the chunk lines
  local chunk = {}
  for i = chunk_start, chunk_end do
    table.insert(chunk, lines[i + 1])
  end
  ------------------------------------------------------------------------------
  -- 2. Check if chunk has [done: ...] or [untoggled], then transform them
  ------------------------------------------------------------------------------
  local has_done_index = nil
  local has_untoggled_index = nil
  for i, line in ipairs(chunk) do
    -- Replace `[done: ...]` -> `` `done: ...` ``
    chunk[i] = line:gsub("%[done:([^%]]+)%]", "`" .. label_done .. "%1`")
    -- Replace `[untoggled]` -> `` `untoggled` ``
    chunk[i] = chunk[i]:gsub("%[untoggled%]", "`untoggled`")
    if chunk[i]:match("`" .. label_done .. ".-`") then
      has_done_index = i
      break
    end
  end
  if not has_done_index then
    for i, line in ipairs(chunk) do
      if line:match("`untoggled`") then
        has_untoggled_index = i
        break
      end
    end
  end
  ------------------------------------------------------------------------------
  -- 3. Helpers to toggle bullet
  ------------------------------------------------------------------------------
  -- Convert '- [ ]' to '- [x]'
  local function bulletToX(line)
    return line:gsub("^(%s*%- )%[%s*%]", "%1[x]")
  end
  -- Convert '- [x]' to '- [ ]'
  local function bulletToBlank(line)
    return line:gsub("^(%s*%- )%[x%]", "%1[ ]")
  end
  ------------------------------------------------------------------------------
  -- 4. Insert or remove label *after* the bracket
  ------------------------------------------------------------------------------
  local function insertLabelAfterBracket(line, label)
    local prefix = line:match("^(%s*%- %[[x ]%])")
    if not prefix then
      return line
    end
    local rest = line:sub(#prefix + 1)
    return prefix .. " " .. label .. rest
  end
  local function removeLabel(line)
    -- If there's a label (like `` `done: ...` `` or `` `untoggled` ``) right after
    -- '- [x]' or '- [ ]', remove it
    return line:gsub("^(%s*%- %[[x ]%])%s+`.-`", "%1")
  end
  ------------------------------------------------------------------------------
  -- 5. Update the buffer with new chunk lines (in place)
  ------------------------------------------------------------------------------
  local function updateBufferWithChunk(new_chunk)
    for idx = chunk_start, chunk_end do
      lines[idx + 1] = new_chunk[idx - chunk_start + 1]
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  ------------------------------------------------------------------------------
  -- 6. Main toggle logic
  ------------------------------------------------------------------------------
  if has_done_index then
    chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub(
      "`" .. label_done .. ".-`",
      "`untoggled`"
    )
    chunk[1] = bulletToBlank(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`untoggled`")
    updateBufferWithChunk(chunk)
    vim.notify("Untoggled", vim.log.levels.INFO)
  elseif has_untoggled_index then
    chunk[has_untoggled_index] = removeLabel(chunk[has_untoggled_index]):gsub(
      "`untoggled`",
      "`" .. label_done .. " " .. timestamp .. "`"
    )
    chunk[1] = bulletToX(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(
      chunk[1],
      "`" .. label_done .. " " .. timestamp .. "`"
    )
    updateBufferWithChunk(chunk)
    vim.notify("Completed", vim.log.levels.INFO)
  else
    -- Save original window view before modifications
    local win = api.nvim_get_current_win()
    local view = api.nvim_win_call(win, function()
      return vim.fn.winsaveview()
    end)
    chunk[1] = bulletToX(chunk[1])
    chunk[1] = insertLabelAfterBracket(
      chunk[1],
      "`" .. label_done .. " " .. timestamp .. "`"
    )
    -- Remove chunk from the original lines
    for i = chunk_end, chunk_start, -1 do
      table.remove(lines, i + 1)
    end
    -- Append chunk under 'tasks_heading'
    local heading_index = nil
    for i, line in ipairs(lines) do
      if line:match("^" .. tasks_heading) then
        heading_index = i
        break
      end
    end
    if heading_index then
      for _, cLine in ipairs(chunk) do
        table.insert(lines, heading_index + 1, cLine)
        heading_index = heading_index + 1
      end
      -- Remove any blank line right after newly inserted chunk
      local after_last_item = heading_index + 1
      if lines[after_last_item] == "" then
        table.remove(lines, after_last_item)
      end
    else
      table.insert(lines, tasks_heading)
      for _, cLine in ipairs(chunk) do
        table.insert(lines, cLine)
      end
      local after_last_item = #lines + 1
      if lines[after_last_item] == "" then
        table.remove(lines, after_last_item)
      end
    end
    -- Update buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.notify("Completed", vim.log.levels.INFO)
    -- Restore window view to preserve scroll position
    api.nvim_win_call(win, function()
      vim.fn.winrestview(view)
    end)
  end
  -- Write changes and restore view to preserve folds
  -- "Update" saves only if the buffer has been modified since the last save
  vim.cmd("silent update")
  vim.cmd("loadview")
end, { desc = "[M]arkdown [T]oggle task and move it to 'done'" })

vim.keymap.set("n", "<leader>mc", function()
  -- Get the current line/row/column
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, _ = cursor_pos[1], cursor_pos[2]
  local line = vim.api.nvim_get_current_line()
  -- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
  if line:match("^%s*$") then
    local final_line = "- [ ] "
    vim.api.nvim_set_current_line(final_line)
    -- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
    vim.api.nvim_win_set_cursor(0, { row, 6 })
    return
  end
  -- 2) Check if line already has a bullet with possible indentation: e.g. "  - Something"
  --    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
  local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
  if bullet then
    -- Convert bullet => bullet .. "[ ] " .. text
    local final_line = bullet .. "[ ] " .. text
    vim.api.nvim_set_current_line(final_line)
    -- Place the cursor right after "[ ] "
    -- bullet length + "[ ] " is bullet_len + 4 characters,
    -- but bullet has trailing spaces, so #bullet includes those.
    local bullet_len = #bullet
    -- We want to land after the brackets (four characters: `[ ] `),
    -- so col = bullet_len + 4 (0-based).
    vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
    return
  end
  -- 3) If there's text, but no bullet => prepend "- [ ] "
  --    and place cursor after the brackets
  local final_line = "- [ ] " .. line
  vim.api.nvim_set_current_line(final_line)
  -- "- [ ] " is 6 characters
  vim.api.nvim_win_set_cursor(0, { row, 6 })
end, { desc = "Toggle [C]heckbox" })

-- - There are some old ones that have more than one H1 heading in them, so when I
--   open one of those old documents, I want to add one more `#` to each heading
vim.keymap.set("n", "<leader>mh", function()
  -- Save the current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  -- I'm using [[ ]] to escape the special characters in a command
  vim.cmd([[:g/\(^$\n\s*#\+\s.*\n^$\)/ .+1 s/^#\+\s/#&/]])
  -- Restore the cursor position
  vim.api.nvim_win_set_cursor(0, cursor_pos)
  -- Clear search highlight
  vim.cmd("nohlsearch")
end, { desc = "[Markdown] Increase [H]eadings without confirmation" })

vim.keymap.set("n", "<leader>mH", function()
  -- Save the current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  -- I'm using [[ ]] to escape the special characters in a command
  vim.cmd([[:g/^\s*#\{2,}\s/ s/^#\(#\+\s.*\)/\1/]])

  -- Restore the cursor position
  vim.api.nvim_win_set_cursor(0, cursor_pos)
  -- Clear search highlight
  vim.cmd("nohlsearch")
end, { desc = "[M]arkdown Decrease [H]eadings without confirmation" })



-- SPELL

-- Keymap to switch spelling language to English
-- To save the language settings configured on each buffer, you need to add
-- "localoptions" to vim.opt.sessionoptions in the `lua/config/options.lua` file
vim.keymap.set("n", "<leader>uWe", function()
  vim.opt.spelllang = "en"
  vim.cmd("echo 'Spell language set to English'")
end, { desc = "[P]Spelling language English" })

-- Keymap to switch spelling language to Spanish
vim.keymap.set("n", "<leader>uWs", function()
  vim.opt.spelllang = "es"
  vim.cmd("echo 'Spell language set to Spanish'")
end, { desc = "[P]Spelling language Spanish" })

-- Keymap to switch spelling language to both spanish and english
vim.keymap.set("n", "<leader>uWb", function()
  vim.opt.spelllang = "en,es"
  vim.cmd("echo 'Spell language set to Spanish and English'")
end, { desc = "[P]Spelling language Spanish and English" })

-- markdown good, accept spell suggestion
-- Add word under the cursor as a good word
vim.keymap.set("n", "<leader>uWa", function()
  vim.cmd("normal! zg")
end, { desc = "[P]Spelling add word to spellfile" })

-- Undo zw, remove the word from the entry in 'spellfile'.
vim.keymap.set("n", "<leader>uWd", function()
  vim.cmd("normal! zug")
end, { desc = "[P]Spelling undo, remove word from list" })

-- Surround

-- Surround the http:// url that the cursor is currently in with ``
vim.keymap.set("n", "gsmu", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Adjust for 0-index in Lua
  -- This makes the `s` optional so it matches both http and https
  local pattern = "https?://[^ ,;'\"<>%s)]*"
  -- Find the starting and ending positions of the URL
  local s, e = string.find(line, pattern)
  while s and e do
    if s <= col and e >= col then
      -- When the cursor is within the URL
      local url = string.sub(line, s, e)
      -- Update the line with backticks around the URL
      local new_line = string.sub(line, 1, s - 1)
          .. "`"
          .. url
          .. "`"
          .. string.sub(line, e + 1)
      vim.api.nvim_set_current_line(new_line)
      vim.cmd("silent write")
      return
    end
    -- Find the next URL in the line
    s, e = string.find(line, pattern, e + 1)
    -- Save the file to update trouble list
  end
  print("No URL found under cursor")
end, { desc = "Add `` surrounding to URL" })

-- This surrounds with inline code
vim.keymap.set("v", "gsmc", function()
  -- Use nvim_replace_termcodes to handle special characters like backticks
  local keys = vim.api.nvim_replace_termcodes("gsa`", true, false, true)
  -- Feed the keys in visual mode ('x' for visual mode)
  vim.api.nvim_feedkeys(keys, "x", false)
  -- I tried these 3, but they didn't work, I assume because of the backtick character
end, { desc = "Surround selection with backticks (inline code)" })

-- This surrounds CURRENT WORD with inline code in NORMAL MODE
vim.keymap.set("n", "gsmw", function()
  -- Use nvim_replace_termcodes to handle special characters like backticks
  local keys = vim.api.nvim_replace_termcodes("gsaiw`", true, false, true)
  -- Feed the keys in visual mode ('x' for visual mode)
  vim.api.nvim_feedkeys(keys, "x", false)
  -- I tried these 3, but they didn't work, I assume because of the backtick character
  -- vim.cmd("normal! gsa`")
  -- vim.cmd([[normal! gsa`]])
  -- vim.cmd("normal! gsa\\`")
end, { desc = "Surround selection with backticks (inline code)" })

-- In visual mode, check if the selected text is already bold and show a message if it is
-- If not, surround it with double asterisks for bold
vim.keymap.set("v", "gsmb", function()
  -- Get the selected text range
  local start_row, start_col = unpack(vim.fn.getpos("'<"), 2, 3)
  local end_row, end_col = unpack(vim.fn.getpos("'>"), 2, 3)
  -- Get the selected lines
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local selected_text =
      table.concat(lines, "\n"):sub(start_col, #lines == 1 and end_col or -1)
  if selected_text:match("^%*%*.*%*%*$") then
    vim.notify("Text already bold", vim.log.levels.INFO)
  else
    vim.cmd("normal 2gsa*")
  end
end, { desc = "[P]BOLD current selection" })

-- -- Multiline unbold attempt
-- -- In normal mode, bold the current word under the cursor
-- -- If already bold, it will unbold the word under the cursor
-- -- If you're in a multiline bold, it will unbold it only if you're on the
-- -- first line
vim.keymap.set("n", "gsmb", function()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_buffer = vim.api.nvim_get_current_buf()
  local start_row = cursor_pos[1] - 1
  local col = cursor_pos[2]
  -- Get the current line
  local line = vim.api.nvim_buf_get_lines(
    current_buffer,
    start_row,
    start_row + 1,
    false
  )[1]
  -- Check if the cursor is on an asterisk
  if line:sub(col + 1, col + 1):match("%*") then
    vim.notify(
      "Cursor is on an asterisk, run inside the bold text",
      vim.log.levels.WARN
    )
    return
  end
  -- Search for '**' to the left of the cursor position
  local left_text = line:sub(1, col)
  local bold_start = left_text:reverse():find("%*%*")
  if bold_start then
    bold_start = col - bold_start
  end
  -- Search for '**' to the right of the cursor position and in following lines
  local right_text = line:sub(col + 1)
  local bold_end = right_text:find("%*%*")
  local end_row = start_row
  while
    not bold_end and end_row < vim.api.nvim_buf_line_count(current_buffer) - 1
  do
    end_row = end_row + 1
    local next_line =
        vim.api.nvim_buf_get_lines(current_buffer, end_row, end_row + 1, false)[1]
    if next_line == "" then
      break
    end
    right_text = right_text .. "\n" .. next_line
    bold_end = right_text:find("%*%*")
  end
  if bold_end then
    bold_end = col + bold_end
  end
  -- Remove '**' markers if found, otherwise bold the word
  if bold_start and bold_end then
    -- Extract lines
    local text_lines =
        vim.api.nvim_buf_get_lines(current_buffer, start_row, end_row + 1, false)
    local text = table.concat(text_lines, "\n")
    -- Calculate positions to correctly remove '**'
    -- vim.notify("bold_start: " .. bold_start .. ", bold_end: " .. bold_end)
    local new_text = text:sub(1, bold_start - 1)
        .. text:sub(bold_start + 2, bold_end - 1)
        .. text:sub(bold_end + 2)
    local new_lines = vim.split(new_text, "\n")
    -- Set new lines in buffer
    vim.api.nvim_buf_set_lines(
      current_buffer,
      start_row,
      end_row + 1,
      false,
      new_lines
    )
    -- vim.notify("Unbolded text", vim.log.levels.INFO)
  else
    -- Bold the word at the cursor position if no bold markers are found
    local before = line:sub(1, col)
    local after = line:sub(col + 1)
    local inside_surround = before:match("%*%*[^%*]*$")
        and after:match("^[^%*]*%*%*")
    if inside_surround then
      vim.cmd("normal gsd*.")
    else
      vim.cmd("normal viw")
      vim.cmd("normal 2gsa*")
    end
    vim.notify("Bolded current word", vim.log.levels.INFO)
  end
end, { desc = "BOLD toggle bold markers" })

--- FILES
---

-- Function to delete the current file with confirmation
local function delete_current_file()
  local current_file = vim.fn.expand("%:p")
  if current_file and current_file ~= "" then
    -- Check if trash utility is installed
    if vim.fn.executable("trash") == 0 then
      vim.api.nvim_echo({
        {
          "- Trash utility not installed. Make sure to install it first\n",
          "ErrorMsg",
        },
        { "- In macOS run `brew install trash`\n", nil },
      }, false, {})
      return
    end
    -- Prompt for confirmation before deleting the file
    vim.ui.input({
      prompt = "Type 'del' to delete the file '" .. current_file .. "': ",
    }, function(input)
      if input == "del" then
        -- Delete the file using trash app
        local success, _ = pcall(function()
          vim.fn.system({ "trash", vim.fn.fnameescape(current_file) })
        end)
        if success then
          vim.api.nvim_echo({
            { "File deleted from disk:\n", "Normal" },
            { current_file,                "Normal" },
          }, false, {})
          -- Close the buffer after deleting the file
          vim.cmd("bd!")
        else
          vim.api.nvim_echo({
            { "Failed to delete file:\n", "ErrorMsg" },
            { current_file,               "ErrorMsg" },
          }, false, {})
        end
      else
        vim.api.nvim_echo({
          { "File deletion canceled.", "Normal" },
        }, false, {})
      end
    end)
  else
    vim.api.nvim_echo({
      { "No file to delete", "WarningMsg" },
    }, false, {})
  end
end

-- Function to copy file path to clipboard
local function copy_filepath_to_clipboard()
  local filePath = vim.fn.expand("%:~") -- Gets the file path relative to the home directory
  vim.fn.setreg("+", filePath)          -- Copy the file path to the clipboard register
  vim.notify(filePath, vim.log.levels.INFO)
  vim.notify("Path copied to clipboard: ", vim.log.levels.INFO)
end

-- Keymaps for copying file path to clipboard
vim.keymap.set(
  "n",
  "<leader>fC",
  copy_filepath_to_clipboard,
  { desc = "[F]ile [C]opy path to clipboard" }
)

-- Keymap to delete the current file
vim.keymap.set("n", "<leader>fD", function()
  delete_current_file()
end, { desc = "[F]ile [D]elete current" })

-- Function to open current file in Finder or ForkLift
local function open_in_file_manager()
  local file_path = vim.fn.expand("%:p")
  if file_path ~= "" then
    -- -- Open in Finder or in ForkLift
    local command = "open -R " .. vim.fn.shellescape(file_path)
    vim.fn.system(command)
    print("Opened file in Finder: " .. file_path)
  else
    print("No file is currently open")
  end
end

vim.keymap.set(
  "n",
  "<leader>fO",
  open_in_file_manager,
  { desc = "Open current file in file explorer" }
)

--- FOLDS

-- Function to fold all headings of a specific level
local function fold_headings_of_level(level)
  -- Move to the top of the file
  vim.cmd("normal! gg")
  -- Get the total number of lines
  local total_lines = vim.fn.line("$")
  for line = 1, total_lines do
    -- Get the content of the current line
    local line_content = vim.fn.getline(line)
    -- "^" -> Ensures the match is at the start of the line
    -- string.rep("#", level) -> Creates a string with 'level' number of "#" characters
    -- "%s" -> Matches any whitespace character after the "#" characters
    -- So this will match `## `, `### `, `#### ` for example, which are markdown headings
    if line_content:match("^" .. string.rep("#", level) .. "%s") then
      -- Move the cursor to the current line
      vim.fn.cursor(line, 1)
      -- Fold the heading if it matches the level
      if vim.fn.foldclosed(line) == -1 then
        vim.cmd("normal! za")
      end
    end
  end
end

local function fold_markdown_headings(levels)
  -- I save the view to know where to jump back after folding
  local saved_view = vim.fn.winsaveview()
  for _, level in ipairs(levels) do
    fold_headings_of_level(level)
  end
  vim.cmd("nohlsearch")
  -- Restore the view to jump to where I was
  vim.fn.winrestview(saved_view)
end

-- Keymap for unfolding markdown headings of level 2 or above
vim.keymap.set("n", "z2", function()
  -- Reloads the file to reflect the changes
  vim.cmd("edit!")
  vim.cmd("normal! zR") -- Unfold all headings
end, { desc = "Unfold all headings level 2 or above" })

-- Keymap for folding markdown headings of level 1 or above
vim.keymap.set("n", "z1", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3, 2, 1 })
end, { desc = "Fold all headings level 1 or above" })

-- Keymap for folding markdown headings of level 2 or above
vim.keymap.set("n", "z2", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3, 2 })
end, { desc = "Fold all headings level 2 or above" })

-- Keymap for folding markdown headings of level 3 or above
vim.keymap.set("n", "z3", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4, 3 })
end, { desc = "Fold all headings level 3 or above" })

-- Keymap for folding markdown headings of level 4 or above
vim.keymap.set("n", "z4", function()
  -- Reloads the file to refresh folds, otherwise you have to re-open neovim
  vim.cmd("edit!")
  -- Unfold everything first or I had issues
  vim.cmd("normal! zR")
  fold_markdown_headings({ 6, 5, 4 })
end, { desc = "Fold all headings level 4 or above" })

-- jummps to the markdown hedading above and then folds it
-- zi by default toggles folding
vim.keymap.set("n", "zi", function()
  -- Difference between normal and normal!
  -- - `normal` executes the command and respects any mappings that might be defined.
  -- - `normal!` executes the command in a "raw" mode, ignoring any mappings.
  vim.cmd("normal <esc>")
  -- This is to fold the line under the cursor
  vim.cmd("normal! za")
  vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold the heading cursor currently on" })

-- NOTES
--

local function insert_date()
  local date = os.date("%Y-%m-%d-%A")
  local dateLine = "[[" .. date .. "]]"                 -- Formatted date line
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0)) -- Get the current row number
  -- Insert both lines: heading and dateLine
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { dateLine })
  -- Enter insert mode at the end of the current line
  -- vim.cmd("startinsert!")
  return dateLine
  -- vim.api.nvim_win_set_cursor(0, { row, #heading })
end

-- parse date line and generate file path components for the daily note
local function parse_date_line(date_line)
  local year, month, day, weekday = date_line:match("%[%[(%d+)%-(%d+)%-(%d+)%-(%w+)%]%]")
  if not (year and month and day and weekday) then
    print("No valid date found in the line")
    return nil
  end
  local month_abbr = os.date("%b", os.time({ year = year, month = month, day = day }))
  local note_dir = string.format("%s/%s/%s-%s", vim.g.notesdir, year, month, month_abbr)
  local daily_note_name = string.format("%s-%s-%s-%s.md", year, month, day, weekday)
  local monthly_note_name = string.format("%s-%s-%s.md", year, month, month_abbr)
  return note_dir, daily_note_name, monthly_note_name
end

local function get_daily_note_path(date_line)
  local note_dir, daily_note_name, _ = parse_date_line(date_line)
  if not note_dir or not daily_note_name then
    return nil
  end
  return note_dir .. "/" .. daily_note_name, daily_note_name
end

local function get_monthly_note_path(date_line)
  local note_dir, _, monthly_note_name = parse_date_line(date_line)
  if not note_dir or not monthly_note_name then
    return nil
  end
  return note_dir .. "/" .. monthly_note_name, monthly_note_name
end

local function create_note(full_path, content)
  if not full_path then
    return
  end
  local note_dir = full_path:match("(.*/)") -- Extract directory path from full path
  -- Ensure the directory exists
  vim.fn.mkdir(note_dir, "p")
  -- Check if the file exists and create it if it doesn't

  if vim.fn.filereadable(full_path) == 0 then
    local file = io.open(full_path, "w")
    if file then
      file:write(content)
      file:close()
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      vim.cmd("bd!")
      -- vim.api.nvim_echo({
      --   { "CREATED DAILY NOTE\n", "WarningMsg" },
      --   { full_path, "WarningMsg" },
      -- }, false, {})
    else
      print("Failed to create file: " .. full_path)
    end
  end
end

local function create_daily_note(date_line)
  local full_path, note_name = get_daily_note_path(date_line)
  if not full_path then
    return
  end
  local content = "# Daily Note " .. note_name .. "\n\n"
      .. "## Contents\n<!-- toc -->\n"
      .. "- [Tasks](#tasks)\n"
      .. "- [Notes](#notes)\n<!-- tocstop -->\n"
      .. "## Tasks \n \n\n"
      .. "## Notes\n- \n\n"
  create_note(full_path, content)
  return full_path
end

local function switch_to_daily_note(date_line)
  local full_path = create_daily_note(date_line)
  if not full_path then
    return nil
  end
  vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

local function switch_to_monthly_note(date_line)
  local full_path, note_name = get_monthly_note_path(date_line)
  if not full_path then
    return
  end
  local content = "# Monthly Note " .. note_name .. "\n\n"
      .. "## Contents\n<!-- toc -->\n"
      .. "- [Important](#important)\n"
      .. "- [Daily Notes](#daily-notes)\n"
      .. "- [Tasks](#Tasks)\n"
      .. "- [Notes](#notes)\n"
      .. "- [Meetings](#meetings)\n<!-- tocstop -->\n"
      .. "## Important \n- \n\n"
      .. "## Daily Notes \n- \n\n"
      .. "## Tasks \n \n\n"
      .. "## Notes\n- \n\n"
      .. "## Meetings\n- \n\n"
  create_note(full_path, content)
  vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

-- Keymap to switch to the daily note or create it if it does not exist
vim.keymap.set("n", "<leader>mw", function()
  local current_line = vim.api.nvim_get_current_line()
  local date_line = current_line:match("%[%[%d+%-%d+%-%d+%-%w+%]%]") or ("[[" .. os.date("%Y-%m-%d-%A") .. "]]")
  switch_to_daily_note(date_line)
end, { desc = "[P]Go to or create daily note" })

-- Keymap to switch to the monthly note or create it if it does not exist
vim.keymap.set("n", "<leader>mm", function()
  local current_line = vim.api.nvim_get_current_line()
  local date_line = current_line:match("%[%[%d+%-%d+%-%d+%-%w+%]%]") or ("[[" .. os.date("%Y-%m-%d-%A") .. "]]")
  switch_to_monthly_note(date_line)
end, { desc = "Go to or create monthly note" })

vim.keymap.set("n", "<leader>wB", function()
  local date_line = insert_date()
  create_daily_note(date_line)
end, { desc = "Create and Add bookmark to daily note" })


-- VS CODE
if vim.g.vscode then
  vim.keymap.set("n", "<leader>sb", "<cmd>Find<cr>")

  vim.keymap.set("n", "<S-h>", "<Cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>")
  vim.keymap.set("n", "<S-l>", "<Cmd>call VSCodeNotify('workbench.action.nextEditor')<CR>")

  -- Increase
  vim.keymap.set("n", "<C-Up>", "<Cmd>call VSCodeNotify('workbench.action.increaseViewHeight')<CR>")
  vim.keymap.set("n", "<C-Down>", "<Cmd>call VSCodeNotify('workbench.action.decreaseViewHeight')<CR>")
  vim.keymap.set("n", "<C-Right>", "<Cmd>call VSCodeNotify('workbench.action.increaseViewWidth')<CR>")
  vim.keymap.set("n", "<C-Left>", "<Cmd>call VSCodeNotify('workbench.action.decreaseViewWidth')<CR>")


  vim.keymap.set({ "n", "v" }, "<A-j>", "<Cmd>call VSCodeNotify('editor.action.moveLinesDownAction')<CR>")

  vim.keymap.set({ "n", "v" }, "<A-k>", "<Cmd>call VSCodeNotify('editor.action.moveLinesUpAction')<CR>")

  -- Files
  vim.keymap.set("n", "<leader>fn", "<Cmd>call VSCodeNotify('workbench.action.files.newUntitledFile')<CR>")
  vim.keymap.set("n", "<C-space>", "<Cmd>call VSCodeNotify('editor.action.toggleWordWrap')<CR>")

  -- Terminal
  vim.keymap.set("n", "<leader>ft", "<Cmd>call VSCodeNotify('workbench.action.terminal.toggleTerminal')<CR>")
  vim.keymap.set("n", "<leader>fT", "<Cmd>call VSCodeNotify('workbench.action.createTerminalEditor')<CR>")

  -- LSP
  vim.keymap.set("n", "<leader>cd", "<Cmd>call VSCodeNotify('editor.action.showHover')<CR>")
  vim.keymap.set("n", "<leader>cl", "<Cmd>call VSCodeNotify('workbench.action.output.toggleOutput')<CR>")
  vim.keymap.set("n", "gd", "<Cmd>call VSCodeNotify('editor.action.revealDefinition')<CR>")
  vim.keymap.set("n", "gD", "<Cmd>call VSCodeNotify('editor.action.revealDeclaration')<CR>")
  vim.keymap.set("n", "gr", "<Cmd>call VSCodeNotify('editor.action.goToReferences')<CR>")
  vim.keymap.set("n", "gI", "<Cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>")
  vim.keymap.set("n", "gy", "<Cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<CR>")
  vim.keymap.set("v", "<leader>cf", "<Cmd>call VSCodeNotify('editor.action.formatSelection')<CR>")
  vim.keymap.set("n", "<leader>cf", "<Cmd>call VSCodeNotify('editor.action.formatDocument')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ca", "<Cmd>call VSCodeNotify('editor.action.quickFix')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>cr", "<Cmd>call VSCodeNotify('editor.action.rename')<CR>")
  vim.keymap.set("n", "<leader>co", "<Cmd>call VSCodeNotify('editor.action.organizeImports')<CR>")

  vim.keymap.set('n', '<leader>dC', "<cmd>call VSCodeNotify('testing.runAtCursor')<CR>")
  vim.keymap.set('n', '<leader>da', "<cmd>call VSCodeNotify('testing.runAll')<CR>")


  -- Windows
  vim.keymap.set({ "n", "v" }, "<leader>wd", "<Cmd>call VSCodeNotify('workbench.action.closeWindow')<CR>")
  vim.keymap.set('n', '<leader>wm', "<cmd>call VSCodeNotify('workbench.action.toggleMaximizeEditorGroup')<CR>")
  vim.keymap.set('n', '<leader>wsm', "<cmd>call VSCodeNotify('workbench.action.toggleMaximizeEditorGroup')<CR>")



  -- Snacks
  vim.keymap.set("n", "<leader>ff", "<Cmd>call VSCodeNotify('workbench.action.quickOpen')<CR>")
  vim.keymap.set("n", "<leader>fb", "<Cmd>call VSCodeNotify('workbench.action.openPreviousEditorFromHistory')<CR>")
  vim.keymap.set("n", "<leader>fB", "<Cmd>call VSCodeNotify('workbench.action.showAllEditors')<CR>")
  vim.keymap.set("n", "<leader>fe", "<Cmd>call VSCodeNotify('workbench.files.action.showActiveFileInExplorer')<CR>")
  vim.keymap.set("n", "<leader>e", "<Cmd>call VSCodeNotify('workbench.explorer.fileView.focus')<CR>")
  vim.keymap.set("n", "<leader>sg", "<Cmd>call VSCodeNotify('workbench.action.findInFiles')<CR>")
  vim.keymap.set("n", "<leader>sC", "<Cmd>call VSCodeNotify('workbench.action.showCommands')<CR>")
  vim.keymap.set("n", "<leader>sk", "<Cmd>call VSCodeNotify('workbench.action.showCommands')<CR>")
  vim.keymap.set("n", "<leader>sh", "<Cmd>call VSCodeNotify('workbench.action.openDocumentationUrl')<CR>")
  vim.keymap.set("n", "<leader>ss", "<Cmd>call VSCodeNotify('workbench.action.gotoSymbol')<CR>")

  vim.keymap.set("n", "<leader>snl", "<Cmd>call VSCodeNotify('workbench.action.output.toggleOutput')<CR>")

  vim.keymap.set("n", "<leader>sr", "<Cmd>call VSCodeNotify('editor.action.startFindReplaceAction')<CR>")
  vim.keymap.set("n", "<leader>sb", "<Cmd>call VSCodeNotify('editor.action.startFindReplaceAction')<CR>")

  --Git
  vim.keymap.set("n", "<leader>gg", "<Cmd>call VSCodeNotify('lazygit.openLazygit')<CR>")
  vim.keymap.set("n", "<leader>gs", "<Cmd>call VSCodeNotify('workbench.scm.active')<CR>")
  vim.keymap.set("n", "<leader>gl", "<Cmd>call VSCodeNotify('gitlens.showQuickFileHistory')<CR>")
  vim.keymap.set("n", "<leader>gb", "<Cmd>call VSCodeNotify('gitlens.toggleFileBlame')<CR>")
  vim.keymap.set("n", "<leader>gd", "<Cmd>call VSCodeNotify('gitlens.toggleFileChanges')<CR>")
  vim.keymap.set("n", "<leader>go", "<Cmd>call VSCodeNotify('gitlens.diffWithPrevious')<CR>")
  vim.keymap.set('n', '<leader>gG', "<cmd>call VSCodeNotify('git-graph.view')<CR>", { silent = true })

  vim.keymap.set("n", "<leader>sd", "<Cmd>call VSCodeNotify('workbench.actions.view.problems')<CR>")
  vim.keymap.set("n", "]d", "<Cmd>call VSCodeNotify('editor.action.marker.next')<CR>")
  vim.keymap.set("n", "[d", "<Cmd>call VSCodeNotify('editor.action.marker.prev')<CR>")


  vim.keymap.set("n", "<leader>uC", "<Cmd>call VSCodeNotify('workbench.action.selectTheme')<CR>")

  vim.keymap.set("n", "<leader>uz", "<Cmd>call VSCodeNotify('workbench.action.toggleZenMode')<CR>")

  vim.keymap.set({ "n", "v", "i" }, "<C-y>", "<Cmd>call VSCodeNotify('acceptSelectedSuggestion')<CR>")

  -- AI
  -- Q
  vim.keymap.set({ "n", "v" }, "<leader>anc", "<Cmd>call VSCodeNotify('aws.amazonq.inline.invokeChat')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>anq", "<Cmd>call VSCodeNotify('aws.amazonq.AmazonQChatView.focus')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>anf", "<Cmd>call VSCodeNotify('aws.amazonq.fixCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ano", "<Cmd>call VSCodeNotify('aws.amazonq.optimizeCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ane", "<Cmd>call VSCodeNotify('aws.amazonq.explainCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>and", "<Cmd>call VSCodeNotify('aws.amazonq.generateUnitTests')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>anr", "<Cmd>call VSCodeNotify('aws.amazonq.refactorCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ans", "<Cmd>call VSCodeNotify('aws.amazonq.sendToPrompt')<CR>")

  -- Cline
  vim.keymap.set({ "n", "v" }, "<leader>aQ", "<Cmd>call VSCodeNotify('amzn-cline.SidebarProvider.focus')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>aq", "<Cmd>call VSCodeNotify('amzn-cline.focusChatInput')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>at", "<Cmd>call VSCodeNotify('amzn-cline.addTerminalOutputToChat')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ae", "<Cmd>call VSCodeNotify('amzn-cline.explainCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ad", "<Cmd>call VSCodeNotify('amzn-cline.dev.createTestTasks')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ag", "<Cmd>call VSCodeNotify('amzn-cline.generateGitCommitMessage')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>ar", "<Cmd>call VSCodeNotify('amzn-cline.improveCode')<CR>")
  vim.keymap.set({ "n", "v" }, "<leader>as", "<Cmd>call VSCodeNotify('amzn-cline.addToChat')<CR>")
end
