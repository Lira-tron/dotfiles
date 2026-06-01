---
name: security-review
description: "Pre-merge security audit with CWE/OWASP mapping"
---

# Security Review

When asked to do a security review, review code for security, or before submitting a pull request:

## Process

1. **Get the diff** — Run `git -P diff <base>..HEAD` (or appropriate range) to capture changes.
2. **Read the diff carefully** — examine each changed line for the patterns below.
3. **Map findings** — For each finding, reference the relevant CWE and OWASP category.
4. **Check for common patterns**:
   - Hardcoded secrets, API keys, passwords (CWE-798)
   - SQL/LDAP/XPath injection (CWE-89, CWE-90, CWE-643)
   - XSS and output encoding issues (CWE-79)
   - Missing input validation (CWE-20)
   - Overly permissive IAM/RBAC policies (CWE-269)
   - Sensitive data in logs (CWE-532)
   - Missing encryption at rest / in transit (CWE-311, CWE-319)
   - IDOR / missing authorization checks (CWE-639, CWE-285)
   - Insecure deserialization (CWE-502)
5. **Suggest remediations** — For each finding, provide a concrete code fix.
6. **Generate summary** — Produce a security review summary suitable for inclusion in a PR description.

## Output Format

```
## Security Review Summary

**Scan Result**: X blockers, Y warnings

### Blockers (must fix before merge)
- [CWE-XX] Description — file:line — Remediation

### Warnings (should fix)
- [CWE-XX] Description — file:line — Remediation

### Passed Checks
- No hardcoded secrets detected
- Input validation present on API endpoints
- ...
```

## References
- CWE: https://cwe.mitre.org/
- OWASP Top 10: https://owasp.org/Top10/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
