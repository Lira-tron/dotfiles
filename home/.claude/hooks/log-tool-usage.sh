#!/bin/bash
# PostToolUse hook (async): Log all tool usage for audit trail
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_DIR="$HOME/knowledge/sessions/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

case "$TOOL_NAME" in
  Bash)
    DETAIL=$(echo "$INPUT" | jq -r '.tool_input.command // ""' | head -c 200)
    ;;
  Write|Edit)
    DETAIL=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  Read)
    DETAIL=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  *)
    DETAIL=$(echo "$INPUT" | jq -r '.tool_input | keys | join(", ")' 2>/dev/null || echo "")
    ;;
esac

echo "$TIMESTAMP | session=$SESSION_ID | tool=$TOOL_NAME | cwd=$CWD | detail=$DETAIL" >> "$LOG_DIR/commandlog.log"

exit 0
