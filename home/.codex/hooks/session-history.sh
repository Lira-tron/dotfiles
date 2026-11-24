#!/bin/bash
# Codex Stop/SessionEnd hook: export readable session history.

set -euo pipefail

TURN_INTERVAL=10
OUTPUT_DIR="${KNOWLEDGE_DIR:-$HOME/knowledge}/sessions"
EVENT=$(cat)

[ "${CODEX_SKIP_SESSION_HISTORY:-0}" = "1" ] && exit 0

CWD=$(echo "$EVENT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$EVENT" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$EVENT" | jq -r '.thread_id // .session_id // empty')

[ -z "$CWD" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0
[ -z "$SESSION_ID" ] && exit 0

{
  set -euo pipefail

  DATE=$(date +%Y-%m-%d)
  SESSION_DIR="$OUTPUT_DIR/$DATE"
  mkdir -p "$SESSION_DIR"

  SAFE_ID="${SESSION_ID:0:8}"
  HISTORY_FILE="$SESSION_DIR/codex-${SAFE_ID}-history.md"
  RENDER_SCRIPT="$(dirname "$0")/render-transcript.py"
  TURN_COUNT=$(python3 "$RENDER_SCRIPT" "$TRANSCRIPT" --count 2>/dev/null)
  [ -z "$TURN_COUNT" ] && TURN_COUNT=0
  [ "$TURN_COUNT" -eq 0 ] && exit 0

  if [ "${SESSION_FINAL:-0}" != "1" ]; then
    if [ "$TURN_COUNT" -ne 1 ] && [ $((TURN_COUNT % TURN_INTERVAL)) -ne 0 ]; then
      exit 0
    fi
  fi

  TEMP_FILE="${HISTORY_FILE}.tmp.$$"
  {
    echo "# Session History"
    echo ""
    echo "- **Session ID**: $SESSION_ID"
    echo "- **Agent**: Codex"
    echo "- **Date**: $(date '+%Y-%m-%d %H:%M')"
    echo "- **Working Directory**: $CWD"
    echo "- **Transcript**: $TRANSCRIPT"
    echo "- **Turns**: $TURN_COUNT"
    echo ""
    echo "---"
    echo ""
    python3 "$RENDER_SCRIPT" "$TRANSCRIPT" 2>/dev/null
  } > "$TEMP_FILE"
  mv "$TEMP_FILE" "$HISTORY_FILE"
} </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
