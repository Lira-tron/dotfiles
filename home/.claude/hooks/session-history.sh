#!/bin/bash
# Claude Code Stop hook: export session history and generate summary.
# Reads hook event from stdin, parses the JSONL transcript, writes history
# markdown, and launches a background summarizer via headless `claude -p`.
# Writes to ~/knowledge/sessions with a "claude-" prefix.

set -euo pipefail

TURN_INTERVAL=10
OUTPUT_DIR="$HOME/knowledge/sessions"
EVENT=$(cat)

# Bypass when caller opts out via env var (e.g. edcom/edcomn aliases for the
# committer agent — avoids spawning the expensive summarizer subprocess).
[ "${CLAUDE_SKIP_SESSION_HISTORY:-0}" = "1" ] && exit 0

CWD=$(echo "$EVENT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$EVENT" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$EVENT" | jq -r '.session_id // empty')

[ -z "$CWD" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0
[ -z "$SESSION_ID" ] && exit 0

# Fire-and-forget: fork everything heavy (turn count + transcript render +
# summarizer) into a detached background subshell so the Stop/SessionEnd hook
# returns immediately to Claude Code. The turn count walks the whole JSONL,
# which adds ~80ms on a 12MB transcript — too much for the foreground path.
{
  set -euo pipefail

DATE=$(date +%Y-%m-%d)
SESSION_DIR="$OUTPUT_DIR/$DATE"
mkdir -p "$SESSION_DIR"

SAFE_ID="${SESSION_ID:0:8}"
AGENT_NAME="claude"
HISTORY_FILE="$SESSION_DIR/${AGENT_NAME}-${SAFE_ID}-history.md"
SUMMARY_FILE="$SESSION_DIR/${AGENT_NAME}-${SAFE_ID}-summary.md"

# Count coalesced turns — Claude Code splits a single assistant reply into
# many JSONL lines (thinking, tool_use, text). The renderer coalesces them
# so one "turn" in the history file maps to one user- or assistant-facing
# message. Bail if the transcript is empty.
RENDER_SCRIPT="$(dirname "$0")/render-transcript.py"
TURN_COUNT=$(python3 "$RENDER_SCRIPT" "$TRANSCRIPT" --count 2>/dev/null)
[ -z "$TURN_COUNT" ] && TURN_COUNT=0
[ "$TURN_COUNT" -eq 0 ] && exit 0

# Skip turn gate if called from SessionEnd (via SESSION_FINAL=1).
if [ "${SESSION_FINAL:-0}" != "1" ]; then
  if [ "$TURN_COUNT" -ne 1 ] && [ $(( TURN_COUNT % TURN_INTERVAL )) -ne 0 ]; then
    exit 0
  fi
fi

# Generate history markdown. The Python renderer drops tool_result-only
# user turns (internal plumbing) and collapses consecutive assistant
# content blocks into one section.
{
  echo "# Session History"
  echo ""
  echo "- **Session ID**: $SESSION_ID"
  echo "- **Agent**: $AGENT_NAME (Claude Code)"
  echo "- **Date**: $(date '+%Y-%m-%d %H:%M')"
  echo "- **Working Directory**: $CWD"
  echo "- **Turns**: $TURN_COUNT"
  echo ""
  echo "---"
  echo ""
  python3 "$RENDER_SCRIPT" "$TRANSCRIPT" 2>/dev/null
} > "$HISTORY_FILE"

# Launch headless summarizer in the background (non-blocking).
if ! command -v claude &>/dev/null; then
  exit 0
fi

SUMMARIZER_PROMPT="You are a technical writer that creates comprehensive session summaries.

Read the session history file at $HISTORY_FILE and write a thorough summary to $SUMMARY_FILE.

The summary MUST use this format:

---
topic: session-claude-$SAFE_ID
date: $DATE
agent: claude
cwd: $CWD
turns: $TURN_COUNT
tags: [session, claude, <key topics extracted from the conversation>]
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
All URLs, links, and file paths shared during the session. Omit if no links were used.

After writing $SUMMARY_FILE, Read ~/.claude/skills/daily-notes/SKILL.md and follow its instructions exactly to update today's daily note. Pass these values:
- agent: claude
- sessionId: $SAFE_ID
- summaryPath: $SUMMARY_FILE
- sessionTitle: <reuse the H1 from $SUMMARY_FILE>
- body: <≤6-line high-level summary of the session>
- links: <every URL and file path mentioned in the session>

Write the files directly. No confirmation needed. Be thorough — this is the primary record of what happened."

cd "$SESSION_DIR"

EMPTY_MCP="$(dirname "$0")/summarizer-empty-mcp.json"

CLAUDE_CODE_USE_BEDROCK=1 claude --bare -p \
  --strict-mcp-config --mcp-config "$EMPTY_MCP" \
  --settings '{"hooks":{},"permissions":{"defaultMode":"bypassPermissions"}}' \
  --permission-mode bypassPermissions \
  --no-session-persistence \
  --model us.anthropic.claude-haiku-4-5-20251001-v1:0 \
  "$SUMMARIZER_PROMPT" \
  >/dev/null 2>&1 &
} </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
