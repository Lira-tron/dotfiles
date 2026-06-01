#!/bin/bash
# Guard hook for tdd-test-writer: blocks Write/Edit to non-test files.
# Reads tool input JSON from stdin, checks file_path.
# Allows: paths containing "test", "Test", "tst", "spec", "Spec", "__tests__", "mock", "Mock", "fixture", "Fixture"
# Denies: everything else (implementation files)

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
  exit 0
fi

if echo "$file_path" | grep -qiE '(test|tst|spec|__tests__|mock|fixture)'; then
  exit 0
fi

# Deny write to non-test file
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "TestWriter is restricted to test files only. This file does not appear to be a test file. Only files with test/spec/mock/fixture in the path are allowed."
  }
}'
exit 0
