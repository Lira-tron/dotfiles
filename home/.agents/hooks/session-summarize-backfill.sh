#!/bin/bash
# Claude/Codex SessionStart hook: summarize session histories with no summary.
#
# session-history.sh renders <agent>-<id>-history.md at Stop/SessionEnd but no
# longer summarizes, so summaries are produced here at the start of the next
# session. Walks the last 7 days of session directories, finds history files
# with no matching -summary.md, and runs the headless summarizer for each — the
# daily-note entry goes to the date the session ran, which may not be today.

set -euo pipefail

DAYS=7
LOCK_FILE="/tmp/agent-session-summarize-backfill.lock"
OUTPUT_DIR="${KNOWLEDGE_DIR:-$HOME/knowledge}/sessions"
JOURNAL_DIR="${KNOWLEDGE_DIR:-$HOME/knowledge}/notes/journal"
EVENT=$(cat)

if [ "${CLAUDE_SKIP_SESSION_HISTORY:-0}" = "1" ] ||
   [ "${CODEX_SKIP_SESSION_HISTORY:-0}" = "1" ]; then
  exit 0
fi

command -v codex &>/dev/null || exit 0
[ -d "$OUTPUT_DIR" ] || exit 0

# The starting session's own history file may still be changing.
CURRENT_AGENT="${SESSION_AGENT:-}"
CURRENT_ID=$(echo "$EVENT" | jq -r '.thread_id // .session_id // empty')
CURRENT_ID="${CURRENT_ID:0:8}"

# Fire-and-forget: each summary is a full headless model run, so detach and let
# the session start immediately.
{
  set -euo pipefail

  # One backfill at a time. Parallel session starts would summarize the same
  # file twice and race each other writing the shared daily note.
  exec 9>"$LOCK_FILE"
  flock -n 9 || exit 0

  for OFFSET in $(seq 0 $((DAYS - 1))); do
    DATE=$(date -d "-$OFFSET day" +%Y-%m-%d)
    SESSION_DIR="$OUTPUT_DIR/$DATE"
    [ -d "$SESSION_DIR" ] || continue

    JOURNAL_FILE="$JOURNAL_DIR/$(date -d "$DATE" '+%Y/%m-%b/%Y-%m-%d-%A').md"

    while IFS= read -r HISTORY_FILE; do
      FILE_NAME=$(basename "$HISTORY_FILE")
      AGENT="${FILE_NAME%%-*}"
      SAFE_ID="${FILE_NAME#"$AGENT-"}"
      SAFE_ID="${SAFE_ID%-history.md}"
      SUMMARY_FILE="${HISTORY_FILE%-history.md}-summary.md"
      if [ "$AGENT" = "$CURRENT_AGENT" ] && [ "$SAFE_ID" = "$CURRENT_ID" ]; then
        continue
      fi

      # Done only when both artifacts exist. Gating on the summary alone strands
      # a session whose run died between writing the summary and the note entry,
      # and the entry check is what keeps the note to one entry per session.
      if [ -f "$SUMMARY_FILE" ] &&
         grep -qF "### $AGENT [$SAFE_ID]" "$JOURNAL_FILE" 2>/dev/null; then
        continue
      fi

      CWD=$(sed -n 's/^- \*\*Working Directory\*\*: //p' "$HISTORY_FILE" | head -1)
      TURN_COUNT=$(sed -n 's/^- \*\*Turns\*\*: //p' "$HISTORY_FILE" | head -1)

      SUMMARIZER_PROMPT="You are a technical writer that creates comprehensive session summaries.

Read the session history file at $HISTORY_FILE and write a thorough summary to $SUMMARY_FILE.

The summary MUST use this format:

---
topic: session-$AGENT-$SAFE_ID
date: $DATE
agent: $AGENT
cwd: $CWD
turns: $TURN_COUNT
tags: [session, $AGENT, <key topics extracted from the conversation>]
---

# <Descriptive title summarizing the session's main accomplishment>

## Context
Why this session started — what the user needed, what problem they were solving.

## What Happened
Detailed narrative of the session — key phases, approaches considered, what worked, what didn't. Write as a coherent story, not a turn-by-turn log.

## Decisions
Each significant decision — options, what was chosen, why. Include tradeoffs.

## Technical Details
Specific implementation details — files created/modified (with paths), commands run, tools used, relevant code snippets.

## Outcome
What state things are in at the end of the session.

## Open Items
Unresolved items, follow-ups, next steps. Omit if none.

## References
All URLs, links, file paths — internal wikis, docs, code browser, AWS docs, Quip, tickets, CRs. Omit if no links were used.

After writing $SUMMARY_FILE, read ~/.claude/skills/daily-notes/SKILL.md and follow its instructions exactly to update the daily note. This session ran on $DATE, so the daily note is exactly $JOURNAL_FILE — use that path and do not build one from today's date. Pass these values:
- agent: $AGENT
- sessionId: $SAFE_ID
- summaryPath: $SUMMARY_FILE
- sessionTitle: <reuse the H1 from $SUMMARY_FILE>
- body: <≤6-line high-level summary of the session>
- links: <every URL, file path, CR, ticket, and doc mentioned in the session>

Write the files directly. No confirmation needed. Be thorough — this is the primary record of what happened."

      # Sequential on purpose: concurrent runs would corrupt the shared daily note.
      # -C is the writable workspace; the journal tree needs --add-dir because it
      # resolves into a different repository than the session directory.
      CODEX_SKIP_SESSION_HISTORY=1 codex exec \
        --ephemeral \
        --skip-git-repo-check \
        -c 'mcp_servers={}' \
        -c 'model_reasoning_effort="low"' \
        -s workspace-write \
        -C "$SESSION_DIR" \
        --add-dir "$JOURNAL_DIR" \
        -m openai.gpt-5.6-luna \
        "$SUMMARIZER_PROMPT" \
        </dev/null >/dev/null 2>&1 || true
    done < <(
      find "$SESSION_DIR" -maxdepth 1 -type f \
        \( -name 'claude-*-history.md' -o -name 'codex-*-history.md' \) |
        sort
    )
  done
} </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
