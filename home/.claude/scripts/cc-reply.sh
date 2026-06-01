#!/usr/bin/env bash
# cc-reply: open the user's $EDITOR with Claude's last message visible (as
# read-only comments), so they can compose a reply seeing the question.
#
# Why this is non-trivial: when invoked via `!cc-reply` from Claude Code's
# prompt input, the surrounding shell has no /dev/tty — so we can't open vim
# in-place. Instead we open a tmux split-window pointed at vim on a tempfile.
# The user edits there; when the split closes we read the tempfile and write
# the answer to stdout (and the clipboard).
#
# Requires: tmux session, vim (or $EDITOR), python3 (for transcript parse).

set -uo pipefail

EDITOR="${EDITOR:-vim}"

if [[ -z "${TMUX:-}" ]]; then
  echo "cc-reply: not inside a tmux session — can't open an interactive editor from \`!\`." >&2
  echo "         Either run inside tmux, or compose your reply directly in the prompt box." >&2
  exit 1
fi

# Find the most recently modified Claude Code transcript across all projects.
TRANSCRIPT=$(/bin/ls -1t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -n1 || true)

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  echo "cc-reply: no Claude Code transcript found under ~/.claude/projects/" >&2
  exit 1
fi

# Extract the last assistant message's text content (skip thinking, tool_use).
QUESTION=$(python3 - "$TRANSCRIPT" <<'PY'
import json, sys
path = sys.argv[1]
last_text_blocks = []
with open(path) as f:
    for line in f:
        try:
            obj = json.loads(line)
        except Exception:
            continue
        msg = obj.get("message") or {}
        if msg.get("role") != "assistant":
            continue
        content = msg.get("content") or []
        texts = [c.get("text", "") for c in content
                 if isinstance(c, dict) and c.get("type") == "text"]
        if texts:
            # Replace, not append — we want only the latest assistant turn.
            last_text_blocks[:] = texts
print("\n\n".join(last_text_blocks).rstrip())
PY
)

if [[ -z "$QUESTION" ]]; then
  QUESTION="(no recent assistant text found)"
fi

# Build the editor buffer. Question lines are prefixed with "# " so they
# render as comments in markdown and are easy to strip on save.
TMPFILE=$(mktemp -t cc-reply.XXXXXX.md)
DONE_FLAG="${TMPFILE}.done"
trap 'rm -f "$TMPFILE" "$DONE_FLAG"' EXIT

{
  echo "# --- Claude's last message (read-only, will be stripped on save) ---"
  printf '%s\n' "$QUESTION" | sed 's/^/# /'
  echo "# --- end of Claude's message ---"
  echo ""
  echo ""
  echo "# Type your reply above this line. Save and quit ($EDITOR :wq) when done."
} > "$TMPFILE"

# Open the editor in a new tmux split. The split has its own TTY — vim works.
# When it exits, we touch the done flag and the split closes (no `read`
# pause, the closing IS the signal).
SPLIT_CMD="$EDITOR +4 \"$TMPFILE\"; touch \"$DONE_FLAG\""
tmux split-window -v -l 70% "$SPLIT_CMD"

# Wait for the split to finish. Poll the flag file rather than the split's
# pane id (simpler, works whether the user :wq's or :q!'s out).
while [[ ! -f "$DONE_FLAG" ]]; do
  sleep 0.2
done

# Strip comment lines and trim leading/trailing blanks.
ANSWER=$(grep -v '^#' "$TMPFILE" | awk 'NF{p=1} p' | tac | awk 'NF{p=1} p' | tac)

if [[ -z "$ANSWER" ]]; then
  echo "cc-reply: empty answer, nothing sent." >&2
  exit 0
fi

# Copy to clipboard if available — `!` output isn't auto-submitted as the
# next prompt; the user pastes from clipboard into the prompt box.
# Best-effort clipboard copy. Suppress all output and never let a clipboard
# failure (e.g., no DISPLAY) propagate a non-zero exit out of this script.
{
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$ANSWER" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$ANSWER" | xsel --clipboard --input
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$ANSWER" | pbcopy
  elif command -v tmux >/dev/null 2>&1; then
    printf '%s' "$ANSWER" | tmux load-buffer -
  fi
} >/dev/null 2>&1 || true

# Print the answer to stdout — this is what slash-command `!cc-reply`
# substitution captures, so it must be ONLY the user's text, nothing else.
# Don't emit anything else to stderr after this point on the success path
# (some launchers treat any stderr as failure).
printf '%s\n' "$ANSWER"
exit 0
