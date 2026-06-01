#!/bin/bash
# Guard hook for tdd-code-writer: blocks Write/Edit to test files.
# Reads tool input JSON from stdin, checks file_path.
# Denies: paths containing "test", "Test", "tst", "spec", "Spec", "__tests__", "mock", "Mock", "fixture", "Fixture"
# Allows: everything else (implementation files)

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
  exit 0
fi

if echo "$file_path" | grep -qiE '(test|tst|spec|__tests__|mock|fixture)'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "CodeWriter is restricted to implementation files only. This file appears to be a test file. Only non-test files are allowed."
    }
  }'
fi

exit 0
