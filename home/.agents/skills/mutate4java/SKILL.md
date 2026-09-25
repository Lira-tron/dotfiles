---
name: mutate4java
description: Install, run, and interpret mutate4java differential mutation testing for individual Java source files. Use for Java mutation scans, manifests, survivor hardening, JaCoCo filtering, or mutate4java CLI questions.
---

# mutate4java

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md),
including unpushed commits and pending task edits.
Pass explicit `--lines` for current added/modified production lines; manifest
defaults and `--since-last-run` do not select unpushed Git changes. Empty
source/line scope is a skip. Inspect recovery backups before even `--scan`.

Run from the workspace containing the owning Maven module. Verify the baseline first, scan selected files, then mutate one file at a time with no more than four workers. Preserve embedded manifests, verify restoration against the exact pre-run source, and require exit `0` with evidence that the selected sites ran.

For Brazil packages, use only when the package intentionally supports the required Maven test flow or when a verified `--test-command` provides the correct module test boundary.
