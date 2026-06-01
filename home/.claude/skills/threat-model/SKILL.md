---
name: threat-model
description: "Generate threat models using STRIDE methodology"
---

# Threat Model

When asked to create a threat model, analyze threats, or prepare for a security review:

## Process

1. **Understand the system** — Read the README, design docs, and service code to identify:
   - Components and services involved
   - Data flows (what data moves where, and how)
   - Trust boundaries (internal vs external, service-to-service, user-facing)
   - Data classification (public, internal, confidential, restricted)
   - Cloud resources used (storage, databases, compute, API gateways)

2. **Apply STRIDE** — For each component and data flow, enumerate threats:
   - **S**poofing — Can an attacker impersonate a user or service?
   - **T**ampering — Can data be modified in transit or at rest?
   - **R**epudiation — Can actions be denied without audit trail?
   - **I**nformation Disclosure — Can sensitive data leak?
   - **D**enial of Service — Can the service be overwhelmed?
   - **E**levation of Privilege — Can an attacker gain unauthorized access?

3. **Map to CWE / OWASP** — Link each threat to the relevant standard reference:
   - Spoofing → CWE-287 (Authentication), CWE-308 (MFA)
   - Tampering → CWE-345 (Insufficient Verification), CWE-311 (Encryption at rest)
   - Repudiation → CWE-778 (Insufficient Logging)
   - Info Disclosure → CWE-311, CWE-319 (Cleartext transmission), CWE-532 (Sensitive data in logs)
   - DoS → CWE-770 (Allocation without limits)
   - EoP → CWE-269 (Improper privilege management), CWE-285 (Improper authorization)

4. **Identify mitigations** — For each threat, document existing controls and gaps.

5. **Generate output** — Produce a structured threat model document.

## Output Format

```
# Threat Model: [Service Name]

## System Overview
- Components: ...
- Data Classification: ...
- Trust Boundaries: ...

## Data Flow Diagram
[Describe the data flows in text form, or include a Mermaid/PlantUML diagram]

## Threats

| ID | Component | STRIDE | Threat | Likelihood | Impact | Mitigation | Reference |
|----|-----------|--------|--------|------------|--------|------------|-----------|
| T1 | API GW    | S      | ...    | High       | High   | ...        | CWE-287   |

## Gaps and Recommendations
- ...
```

## References
- CWE: https://cwe.mitre.org/
- OWASP Top 10: https://owasp.org/Top10/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
