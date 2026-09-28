---
name: nvim-agent-comments
description: Reads and acts on Neovim agent comments, appends JSON replies, and returns full answers with relevant code excerpts in chat. Use for pasted thread references with a store path, mentions of Neovim agent comments, or repositories containing .ai/comments/nvim-agent-comments.json or .nvim-agent-comments.json.
---

# nvim-agent-comments

Read and update source-anchored conversation threads in `.ai/comments/nvim-agent-comments.json`, relative to the Git repository or worktree root.

## Start here

When a pasted reference supplies a comment-store path, read that exact file and resolve source paths from its repository root. Otherwise, find the nearest Git repository or worktree root for the commented source file and read `.ai/comments/nvim-agent-comments.json` there. Read the path directly: `.ai/` may be globally ignored by Git and omitted from ordinary file searches.

When discovering the default store, if the new store is absent, check the legacy `.nvim-agent-comments.json` at the same root. If both files exist, use the new store and leave the legacy file untouched; do not merge them automatically. If neither exists, the project has no saved agent comments.

Do not edit comment text or anchors unless the user explicitly asks you to. You may append an agent reply after handling a comment, as described below.

Read each comment and its conversation before determining the requested action:

- If it requests a change, make the change. Ask a focused question only when the answer affects the implementation.
- If it asks a question, quote the relevant source and explain it in context.

The top-level object contains `version` (currently `1`) and `comments`. Each comment's `path` is relative to the repository root, not to `.ai/comments/`. To inspect one file, select records whose `path` exactly matches its project-relative POSIX path.

Comments have an optional `type`: `comment` (general feedback) or `issue` (a problem to address). The type applies to the entire thread; replies do not have separate types. Older records without a type are Comments. Preserve the type when appending a reply.

Comments also have an optional `state`: `open` or `done`; absent means open. Skip DONE threads in a general sweep unless the user explicitly asks to revisit them. Preserve the state when appending an agent reply and do not mark threads DONE automatically. This completion state is separate from the anchor's `status` (`resolved` or `stale`).

Comments may have a stable project-local `thread_number`. When the user names “thread #2”, select the comment whose `thread_number` is `2`; never substitute its array position. Preserve this number, the comment `id`, and the top-level `next_thread_number` counter. Include the thread number in your report when present, so the user can discuss threads one by one.

For a pasted list such as “threads #2, #5”, handle only those threads in the supplied store. Match an explicit `ID` reference against `id`. If the instruction says “Skip DONE threads”, check their current state when reading the store and skip any that are now DONE.

Read the whole conversation: `body` is the original user message, followed by `replies` in order. A reply with `role: "user"` is a follow-up; `role: "agent"` or an absent role is an agent answer. Act on the latest unanswered user message, using earlier messages as context. If several user messages follow the last agent answer, address them together. Do not repeat work already answered unless the user asks you to revisit it.

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
2. Interpret the latest user message in the context of the source and the full conversation.
3. Explain the attached source when the user asks a question.
4. Answer the question or make the requested change.
5. Run relevant tests after code changes.
6. Append the full answer or completed-change explanation to the comment's `replies` array.
7. Return the full answer in the chat conversation, including the thread number, comment ID, resolved location, and relevant code excerpts.

A reply is an object with `role: "agent"` and a non-empty `body`, for example `{"role": "agent", "body": "Added the timeout check and verified the retry tests."}`. Re-read the active store immediately before replying and locate the comment by its `id`; do not recreate a comment that the user deleted. Preserve the latest fields, thread numbers, counter, other comments, and all user and agent replies, and create `replies` as an array when it is absent.

Do not run a command just to obtain a timestamp; `created_at` is optional and should only be included when the time is already available. Write the store atomically. If it changes while preparing the update, reload it and reapply the reply. Do not append a reply when the requested work failed or is incomplete.

After successfully handling a thread, saving the JSON reply and answering in chat are both required. Return the full explanation in chat so the user can keep discussing it; a confirmation that the JSON was updated or a short completion summary is insufficient. For code questions and changes, include a relevant fenced code snippet from the source you read, explain how it answers the latest user message, and report any validation performed. Give each requested thread its own answer, identified by thread number or ID. Leave out unrelated implementation details.

Use this format for an explanation:

````markdown
### Thread #2 (`c_example`) at `lua/example.lua:21`

> Handle the timeout before retrying

```lua
local result = fetch_user(id)
```

`fetch_user` can time out before the retry branch runs. The comment asks for timeout handling at this call site.
````

For a range, write the location as `path:start-end` and quote the relevant range. For a stale comment, show its original range and explain why resolution failed. Include stored context when it helps the user identify the intended code. Never invent a current location.

Do not delete, edit, re-anchor, or mark a comment complete unless the user asks. Appending the reply described above is the only automatic store edit.

## Failures

If the store contains malformed JSON, an unsupported version, invalid paths, or invalid records, report the exact problem and leave the file untouched. Never repair malformed JSON automatically.
