---
name: dry4go
description: Install, run, and interpret dry4go structural duplicate detection for Go functions. Use for Go DRY analysis, duplicate-candidate review, threshold tuning, or dry4go CLI questions.
---

# dry4go

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md),
including unpushed commits and pending task edits.
Run on selected files, with existing code as comparison context where useful.
Only pairs involving an affected function belong to the gate; an empty scope
is a skip, not a request to scan the whole project.

Treat every result as a candidate, not an automatic refactor. Confirm that both locations duplicate knowledge or responsibility before changing code. A clean process exit does not mean no duplicates were found.
