#!/bin/bash
# PreToolUse hook: Block direct git commit. All commits must go through the
# committer agent (which has hooks: {}). This hook fires for every Bash tool
# call — only acts on git commit.
INPUT=$(cat)

# Bypass for committer agent
[ "$(echo "$INPUT" | jq -r '.agent_type // empty')" = "committer" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block git commit — extract subcommand skipping global options that take a value
GIT_SUBCMD=$(echo "$COMMAND" | awk '{
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
      "permissionDecisionReason": "Direct git commit is not allowed. Delegate to the committer agent via /commit or Agent(subagent_type=\"committer\")."
    }
  }'
  exit 0
fi

exit 0
