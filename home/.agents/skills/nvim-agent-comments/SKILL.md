---
name: nvim-agent-comments
description: Reads and acts on project-local Neovim agent comments and appends replies. Use when a repository contains .ai/comments/nvim-agent-comments.json, a legacy .nvim-agent-comments.json, or the user mentions Neovim agent comments.
---

# nvim-agent-comments

This plugin lets developers attach instructions to source lines from Neovim. Its store is `.ai/comments/nvim-agent-comments.json`, relative to the Git repository or worktree root.

## Start here

Find the nearest Git repository or worktree root for the commented source file, then read `.ai/comments/nvim-agent-comments.json` there. Read this path directly: `.ai/` may be globally ignored by Git and omitted from ordinary file searches.

If the new store is absent, check the legacy `.nvim-agent-comments.json` at the same root. The updated plugin migrates a valid legacy store on project access. If both files exist, use the new store and leave the legacy file untouched; do not merge them automatically. If neither exists, the project has no saved agent comments. A custom `store_name` is a filename within `.ai/comments/`; the old default name `.nvim-agent-comments.json` is an alias for the new default.

Do not edit comment text or anchors unless the user explicitly asks you to. You may append an agent reply after handling a comment, as described below.

Handle each comment based on its body:

- If it requests a change, make the change. Ask a focused question only when the answer affects the implementation.
- If it asks a question, quote the relevant source and explain it in context.

The top-level object contains `version` and `comments`. Each comment's `path` is relative to the repository root, not to `.ai/comments/`. To inspect one file, select records whose `path` exactly matches its project-relative POSIX path.

Comments have an optional `type`: `comment` (general feedback) or `issue` (a problem to address). Older records without a type are Comments. Use the body to determine the requested action, and preserve the type when appending a reply.

## Resolve an anchor

The stored range records where the comment was created. Source edits may have moved it. Resolve the range before acting:

```text
for each comment
  read comment.path from the repository root
  find every exact occurrence of comment.context
  if there is exactly one match
    resolved_start = match_start + (context_start_offset or 0)
    resolved_end = resolved_start + end_line - start_line
  else
    report the comment as stale without changing its stored record
```

Line numbers are one-based. `context_start_offset` is zero-based and defaults to zero when absent. Compare complete lines, including whitespace.

Use the resolved range only when the context has one match. If the file is missing or the context has zero or several matches, do not guess. Report the comment ID, path, original range, body, and stale status.

## Act on comments

For each resolved comment:

1. Read the resolved range and nearby code.
2. Interpret the body in that local context.
3. Explain the attached source when the user asks a question.
4. Answer the question or make the requested change.
5. Run relevant tests after code changes.
6. Append a reply to the comment's `replies` array summarizing the answer or completed change.
7. Report the comment ID, resolved location, and result.

A reply is an object with a non-empty `body`, for example `{"body": "Added the timeout check and verified the retry tests."}`. Re-read the active store immediately before replying and locate the comment by its `id`; do not recreate a comment that the user deleted. Preserve the latest fields, other comments, and existing replies, and create `replies` as an array when it is absent.

Do not run a command just to obtain a timestamp; `created_at` is optional and should only be included when the time is already available. Write the store atomically. If it changes while preparing the update, reload it and reapply the reply. Do not append a reply when the requested work failed or is incomplete. Neovim displays replies beneath the original comment and refreshes when the store changes.

Give enough context that the user does not need to reopen the file. Leave out unrelated implementation details.

Use this format for an explanation:

````markdown
### `c_example` at `lua/example.lua:21`

> Handle the timeout before retrying

```lua
local result = fetch_user(id)
```

`fetch_user` can time out before the retry branch runs. The comment asks for timeout handling at this call site.
````

For a range, write the location as `path:start-end` and quote the relevant range. For a stale comment, show its original range and explain why resolution failed. Include stored context when it helps the user identify the intended code. Never invent a current location.

Do not delete, edit, re-anchor, or mark a comment complete unless the user asks. Appending the reply described above is the only automatic store edit.

## Neovim commands

Use these commands when explaining how to manage comments:

```text
:NvimAgentCommentsAdd                 add at the current line
:NvimAgentCommentsAddVisual           add over a visual line range
:NvimAgentCommentsEdit                edit at the current line
:NvimAgentCommentsDelete              delete at the current line
:NvimAgentCommentsJump                jump to an anchor
:NvimAgentCommentsList                browse, search, and delete with Snacks
:NvimAgentCommentsSearch              open the simple comment search
:NvimAgentCommentsToggle              show or hide comments without deleting
:NvimAgentCommentsReanchor            attach a stale comment to a line or range
:NvimAgentCommentsRetrieve [path]     emit project comments as JSON
```

Adding and editing open a Markdown editor below the source, starting at three rows and growing with text. New entries default to Comment; Ctrl-T switches between Comment and Issue in the editor. In Insert mode, Enter adds a newline and Escape enters Normal mode. Ctrl-S or Ctrl-Enter saves and closes; Normal-mode `q` or Enter also saves. Normal-mode Escape or Ctrl-C cancels without saving. The Snacks picker supports Ctrl-D to delete the highlighted comment and its replies. Saved comments render as virtual lines and do not alter source text.

## Failures

If the store contains malformed JSON, an unsupported version, invalid paths, or invalid records, report the exact problem and leave the file untouched. Never repair malformed JSON automatically.
