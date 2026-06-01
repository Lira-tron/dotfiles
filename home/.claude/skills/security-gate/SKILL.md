---
name: security-gate
description: "Automatic security scanning on every code change with CWE/OWASP mapping"
effort: medium
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      type: command
      command: "echo 'Security gate: review the file that was just written/edited for common vulnerabilities and report any findings with CWE/OWASP references'"
---

# Security Gate

This skill provides continuous security scanning as you code. It activates automatically after every Write or Edit operation.

## How it works

When a file is written or edited, automatically:

1. **Review the changed file** for the patterns listed below.
2. **Map findings** — For each finding, reference the relevant CWE and OWASP category.
3. **Report inline** — Show findings concisely without interrupting flow:
   ```
   Security: 1 warning in auth_handler.py
   - [CWE-20] Input not validated on line 45 — add server-side validation
   ```
4. **Block on critical** — If a critical finding is detected (hardcoded secrets, SQL injection), flag it prominently.

## Patterns to flag

- Hardcoded secrets, API keys, passwords (CWE-798)
- SQL/LDAP injection via concatenation (CWE-89, CWE-90)
- XSS / output without encoding (CWE-79)
- Missing input validation (CWE-20)
- Sensitive data in logs (CWE-532)
- `eval`/`exec` of untrusted input (CWE-95)
- Cleartext credentials in transit/storage (CWE-319, CWE-311)
- Insecure deserialization (CWE-502)
- Broken authentication/authorization (CWE-287, CWE-285)

## Severity mapping
- **Blocker**: Hardcoded credentials, private keys, SQL injection → must fix before proceeding
- **Warning**: Missing input validation, sensitive data in logs, overly broad permissions → should fix
- **Info**: Style issues, missing comments → optional
