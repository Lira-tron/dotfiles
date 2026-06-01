---
name: daily-notes
description: Create or update today's daily note at `~/knowledge/notes/journal/YYYY/MM-MMM/YYYY-MM-DD-DayName.md`, appending or replacing a session entry under `## Agent Summary`. Use when the user asks to update the daily note, log a session, append to the journal, or when invoked by the session-history hook after a session summary is written.
---

# Daily Notes

Create or update today's daily note. Append or replace one session entry under `## Agent Summary` while preserving everything else.

## Required inputs

The caller (interactive user or session-history hook) provides:

- `agent` — agent name (e.g. `claude`, `gen`, `planner`)
- `sessionId` — short 8-char ID (e.g. `023a9d1d`)
- `summaryPath` — absolute path to the session summary file
- `sessionTitle` — descriptive title (reuse the H1 from the summary file)
- `body` — high-level summary, ≤6 lines (replace each time to reflect all work done)
- `links` — every URL and file path shared in the session

If any are missing, derive what you can from `summaryPath` (read it; the H1 is the title; the frontmatter has agent and date) and ask for the rest.

## Path

`~/knowledge/notes/journal/YYYY/MM-MMM/YYYY-MM-DD-DayName.md`

- `YYYY` = 4-digit year (e.g. `2026`)
- `MM-MMM` = 2-digit month + 3-letter name, capitalized (`05-May`, `06-Jun`, `12-Dec`)
- `DayName` = full day name, capitalized (`Monday`, `Tuesday`, …)

Build the path from today's date with `date '+%Y/%m-%b/%Y-%m-%d-%A'` (note: `%b` is locale-abbreviated month, capitalize the first letter).

⚠️ Always use this absolute path. Never write relative to `cwd`.

## Workflow

1. Compute today's path.
2. Check if the file exists.
3. **If missing**: create the parent directory if needed, then write the file using the full template below, then add the Agent Summary entry.
4. **If exists**: only modify the `## Agent Summary` section. Do not touch any other section.

## Full template (use only when creating the file)

```markdown
# Daily Note YYYY-MM-DD-DayName.md

## Contents

<!-- toc -->
- [Tasks](#tasks)
- [Actions](#actions)
- [Notes](#notes)
- [Agent Summary](#agent-summary)
<!-- tocstop -->

## Tasks

## Actions

-

## Notes

## Agent Summary
```

Replace `YYYY-MM-DD-DayName` in the H1 with today's actual filename stem.

## Agent Summary entry format

Each session entry under `## Agent Summary`:

```markdown
### <agent> [<sessionId>](<summaryPath>) <sessionTitle>
<body — ≤6 lines>

**Links**:
- <link 1>
- <link 2>
```

## Update rules

- **One entry per session.** Match by `### <agent> [<sessionId>]` prefix.
- If that prefix already exists in `## Agent Summary`: **replace** that entire section (from its `###` line up to but not including the next `###` or end of file) with the new content.
- If it does not exist: **append** the new entry at the end of `## Agent Summary`.
- **Replace `body`** each time — it should reflect all work in the session, not just the latest turn.
- **Append `links`** — never remove existing links. Deduplicate by exact match before writing.
- **Never touch other sections** (`## Tasks`, `## Actions`, `## Notes`) on an existing file.
- **Never ask permission** to update.

## Examples

Today is Sunday 2026-05-31. Path: `~/knowledge/notes/journal/2026/05-May/2026-05-31-Sunday.md`.

New entry:

```markdown
### claude [023a9d1d](~/knowledge/sessions/2026-05-31/claude-023a9d1d-summary.md) Verified Claude Settings Configuration
Verified all six critical Claude configuration settings in `~/.claude/settings.json`,
including extended thinking mode, ultra-high effort, auto memory, away summaries,
and full-screen TUI mode. Confirmed each setting present with line-number references.

**Links**:
- ~/knowledge/sessions/2026-05-31/claude-023a9d1d-summary.md
```
