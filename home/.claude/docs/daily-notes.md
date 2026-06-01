---
inclusion: auto
description: Daily notes format and location
globs: ["**/*"]
---

# Daily Notes

## Location

`~/knowledge/notes/journal/YYYY/MM-MMM/YYYY-MM-DD-DayName.md` — ⚠️ This path is absolute. NEVER create notes relative to the current working directory.

## Daily Note Template

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

## Agent Summary Format

Locate the `## Agent Summary` section and add/update a session entry:

```markdown
### <agent-name> [sessionId](~/knowledge/sessions/YYYY-MM-DD/agent-sessionId-summary.md)  Descriptive Session Title
{High-level summary of entire session (no more than 6 lines) - REPLACE each time to reflect all work done}

**Links**:
- {APPEND all links shared during conversation — URLs, file paths, docs}
```

- Check for duplicate links before appending

- `agent-name` is the agent that ran the session (e.g., `gen`, `planner`, `tech-writer`)
- `sessionId` is the short 8-char conversation ID (e.g., `0c82f601`)
- The link target is the path to the summary file (e.g., `~/knowledge/sessions/2026-03-06/gen-0c82f601-summary.md`)

## Rules

- ✅ If the daily note file does NOT exist, create it using the full template above, then update the `## Agent Summary` section
- ✅ If the file already exists, ONLY update the `## Agent Summary` section
- ✅ ONE session entry per chat session, REPLACE summary, APPEND actions/links
- ✅ PRESERVE all existing content outside Agent Summary
- ✅ Collect ALL links shared during the conversation and include them in **Links**
- ❌ NEVER ask permission to update
- ❌ NEVER remove previous action bullets or links
- ❌ NEVER modify sections other than Agent Summary on existing notes


