#!/bin/bash
# PreToolUse hook: Block direct git commit and cr commands.
# All commits must go through the committer agent.
INPUT=$(cat)

# Claude identifies the subagent in the hook payload. Codex gives the custom
# committer agent this marker through its shell environment policy.
if [ "$(echo "$INPUT" | jq -r '.agent_type // empty')" = "committer" ] ||
   [ "${CODEX_COMMITTER_AGENT:-}" = "1" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block git commit — extract subcommand skipping global options that take a value.
GIT_SUBCMD=$(echo "$COMMAND" | awk '{
  if ($1 != "git") exit
  for (i=2; i<=NF; i++) {
    if ($i ~ /^-/) {
      # flags that consume the next word: -c, -C, --git-dir, --work-tree, etc.
      if ($i ~ /^(-c|-C|--git-dir|--work-tree|--namespace|--config-env)$/) i++
    } else { print $i; exit }
  }
}')
if [ "$GIT_SUBCMD" = "commit" ]; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "Direct git commit is not allowed. Delegate to the committer agent."
    }
  }'
  exit 0
fi

# Block cr commands.
if echo "$COMMAND" | grep -qE '^[[:space:]]*cr([[:space:]]|$)'; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "Direct cr command is not allowed. Delegate to the committer agent with \"create a CR\" in the prompt."
    }
  }'
  exit 0
fi

exit 0
