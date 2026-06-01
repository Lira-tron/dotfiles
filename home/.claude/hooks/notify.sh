#!/bin/bash
# Notification + Stop hook: send a desktop notification to the host terminal
# (Ghostty on the Mac) by emitting OSC 9 wrapped in tmux DCS passthrough.
#
# Wiring: triggered by the "Notification" and "Stop" hook events in
# ~/.claude/settings.json. Reads the hook JSON payload from stdin.
set -u

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
HOOK_EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""')
MESSAGE=$(printf '%s' "$INPUT" | jq -r '.message // ""')

SESSION_NAME=""
if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
  SESSION_NAME=$(tmux display -p -t "$TMUX_PANE" '#S' 2>/dev/null || true)
fi
[ -z "$SESSION_NAME" ] && SESSION_NAME="${HOSTNAME%%.*}"

case "$HOOK_EVENT" in
  Notification)
    BODY="${MESSAGE:-Claude needs input}"
    ;;
  Stop)
    BODY="${MESSAGE:-Turn finished}"
    ;;
  SubagentStop)
    BODY="${MESSAGE:-Subagent finished}"
    ;;
  *)
    BODY="${MESSAGE:-$HOOK_EVENT}"
    ;;
esac

# Strip control chars from BODY so they don't break the OSC sequence.
BODY=$(printf '%s' "$BODY" | tr -d '\000-\037\177')

TITLE="[$SESSION_NAME] Claude: $BODY"

ESC=$'\033'
BEL=$'\007'
OSC9="${ESC}]9;${TITLE}${BEL}"

LOG="$HOME/.claude/audit-logs/notify.log"
mkdir -p "$(dirname "$LOG")"
log() { printf '%s | %s\n' "$(date -u +%FT%TZ)" "$*" >> "$LOG"; }

log "event=$HOOK_EVENT session=$SESSION_NAME tmux=${TMUX:-none} pane=${TMUX_PANE:-none} title=$TITLE"

if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
  PANE_TTY=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null || true)
  # tmux DCS passthrough: ESC P tmux ; <payload-with-doubled-ESC> ESC \
  PAYLOAD="${OSC9//$ESC/$ESC$ESC}"
  WRAPPED="${ESC}Ptmux;${PAYLOAD}${ESC}\\"
  log "pane_tty=$PANE_TTY writable=$([ -w "$PANE_TTY" ] && echo yes || echo no)"
  if [ -n "$PANE_TTY" ] && [ -w "$PANE_TTY" ]; then
    printf '%s' "$WRAPPED" > "$PANE_TTY" 2>>"$LOG" && log "wrote OSC9 via DCS passthrough" || log "write FAILED"
  else
    log "skipped: pane tty not writable"
  fi
else
  if [ -t 2 ]; then
    printf '%s' "$OSC9" >&2
    log "wrote OSC9 to stderr (no tmux)"
  else
    log "skipped: no tmux, stderr not a tty"
  fi
fi

exit 0
