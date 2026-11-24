---
name: summary
description: Recap the current conversation's goal, progress, recent decisions, and next steps. Use when the user asks for a session summary, asks where we left off, or wants a reminder of the task in progress.
---

Help the user regain context and see how to resume the task.

1. Read the available conversation, including any earlier session summary, to
   identify the overall goal, agreed scope, and unfinished work.
2. Focus on roughly the last 10 substantive user and assistant messages to
   establish the current state. Count messages rather than tool calls or routine
   progress updates; use all messages when fewer are available.
3. Apply the user's latest corrections and decisions to the earlier context.
   Keep the original objective through temporary tangents; switch objectives
   when the user clearly changed tasks.
4. Separate completed and verified work from plans, attempts, and unresolved
   questions. Derive next steps from the remaining agreed work. If it is
   complete, say so instead of inventing more tasks.

Use the conversation as the source. If missing context materially limits the
recap, briefly say what is unavailable. Consult an existing transcript only when
its identity is known to match this session and the missing detail matters;
keep unrelated sessions out of the recap.

Respond directly in chat, usually within 200 words:

- Start with one sentence explaining what this session is about and why.
- Briefly cover completed work, the current focus, and recent decisions that
  affect the task. Include a blocker or pending question when relevant.
- End with up to three concrete next steps in execution order, making the
  immediate next action clear. Include a file, branch, or command only when it
  helps the user resume.

Keep the recap focused on the task rather than narrating every message. This
skill reports status; listing next steps does not itself authorize new work.
Save a summary file only when the user requests one.
