#!/bin/bash
# PreToolUse hook: block writes containing hardcoded secrets or common vulnerabilities.
# Exit 2 = hard block (BLOCKER), exit 0 with output = warning.

set -euo pipefail

INPUT=$(cat)

# Extract the file content being written
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

if [ -z "$CONTENT" ]; then
    exit 0
fi

FINDINGS=""

# Check for hardcoded AWS keys (CWE-798)
if echo "$CONTENT" | grep -qE '(AKIA[0-9A-Z]{16}|aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40})'; then
    FINDINGS="${FINDINGS}\n[BLOCKER] [CWE-798] Hardcoded AWS credentials detected in ${FILE_PATH}"
fi

# Check for private keys (CWE-798)
if echo "$CONTENT" | grep -qE -- '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'; then
    FINDINGS="${FINDINGS}\n[BLOCKER] [CWE-798] Private key embedded in ${FILE_PATH}"
fi

# Check for hardcoded passwords (CWE-798)
if echo "$CONTENT" | grep -qiE '(password|passwd|secret)\s*=\s*["\x27][^"\x27]{8,}["\x27]'; then
    FINDINGS="${FINDINGS}\n[WARNING] [CWE-798] Possible hardcoded password in ${FILE_PATH}"
fi

# Check for SQL injection patterns (CWE-89)
if echo "$CONTENT" | grep -qE '((execute|query)\s*\(\s*["\x27].*\+.*["\x27]|f".*SELECT.*\{|format\(.*SELECT)'; then
    FINDINGS="${FINDINGS}\n[WARNING] [CWE-89] Possible SQL injection via string concatenation in ${FILE_PATH}"
fi

# Check for sensitive data logging (CWE-532)
if echo "$CONTENT" | grep -qiE '(log|print|console\.log|logger)\s*\(.*\b(password|secret|token|api_key|ssn|credit_card)\b'; then
    FINDINGS="${FINDINGS}\n[WARNING] [CWE-532] Possible sensitive data in log statement in ${FILE_PATH}"
fi

# Check for eval/exec of untrusted input (CWE-95)
if echo "$CONTENT" | grep -qE '(eval|exec)\s*\(.*\b(request|input|params|args|user)\b'; then
    FINDINGS="${FINDINGS}\n[WARNING] [CWE-95] Possible code injection via eval/exec of untrusted input in ${FILE_PATH}"
fi

if [ -n "$FINDINGS" ]; then
    HAS_BLOCKER=$(echo -e "$FINDINGS" | grep -c "\[BLOCKER\]" || true)
    echo -e "Security scan findings for ${FILE_PATH}:${FINDINGS}"
    if [ "$HAS_BLOCKER" -gt 0 ]; then
        exit 2
    fi
fi

exit 0
