---
name: iam-audit
description: "Audit IAM policies in CDK/CloudFormation/Terraform for least-privilege violations"
---

# IAM Audit

When asked to review IAM policies, audit permissions, or check for least-privilege compliance:

## Process

1. **Find IAM definitions** — Search the codebase for IAM policy definitions:
   - CDK: Look for `PolicyStatement`, `Role`, `Policy`, `Grant` calls
   - CloudFormation: Look for `AWS::IAM::Role`, `AWS::IAM::Policy` resources
   - Terraform: Look for `aws_iam_role`, `aws_iam_policy` resources
   - Raw JSON/YAML policy documents

2. **Check for violations** — Flag these patterns:
   - `Action: "*"` or `Resource: "*"` (overly broad — CWE-269)
   - Missing `Condition` blocks on sensitive actions
   - `Effect: Allow` on `iam:*`, `s3:*`, `ec2:*` without resource scoping
   - Cross-account access without external ID conditions
   - Missing `aws:SourceArn` or `aws:SourceAccount` conditions (confused deputy)
   - Long-lived credentials instead of role assumption
   - Admin-level policies attached to service roles
   - `NotAction` / `NotResource` patterns (often misunderstood)

3. **Suggest fixes** — For each violation:
   - Provide the minimal permission set needed
   - Scope resources to specific ARNs
   - Add appropriate conditions

4. **Generate report** — Produce an audit summary.

## Output Format

```
# IAM Audit Report

**Files Scanned**: X
**Policies Found**: X
**Violations**: X (Y critical, Z warnings)

## Findings

### [Critical] Wildcard action on S3 (CWE-269)
- File: `cdk/stack.py:45`
- Current: `s3:*` on `*`
- Recommended: Scope to specific actions and bucket ARN
- Fix: [code snippet]

### [Warning] Missing condition block
...
```

## References
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- CWE-269 Improper privilege management: https://cwe.mitre.org/data/definitions/269.html
