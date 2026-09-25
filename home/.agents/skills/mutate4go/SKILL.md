---
name: mutate4go
description: Install, run, and interpret mutate4go differential mutation testing for individual Go source files. Use for mutation scans, manifests, survivor hardening, coverage filtering, or mutate4go CLI questions.
---

# mutate4go

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md),
including unpushed commits and pending task edits.
Pass explicit `--lines` for current added/modified production lines; manifest
defaults and `--since-last-run` do not select unpushed Git changes. Empty
source/line scope is a skip. Inspect recovery backups before even `--scan`.

Use the shared quality-tool manager and run from the owning Go module. Verify the baseline first, scan each selected file, then mutate one file at a time with no more than four workers. Preserve embedded manifests and verify restoration against the exact pre-run source.

Important: current `mutate4go` exits successfully even when mutants survive. The gate passes only when the report says `Survived: 0` and no operational error occurred.
