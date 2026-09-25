---
name: dry4java
description: Install, run, and interpret dry4java structural duplicate detection for Java declarations. Use for Java DRY analysis, duplicate-candidate review, threshold tuning, or dry4java CLI questions.
---

# dry4java

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md),
including unpushed commits and pending task edits.
Run on selected files, with existing code as comparison context where useful.
Only pairs involving an affected declaration belong to the gate; an empty scope
is a skip, not a request to scan the whole project.

Treat results as review candidates. Confirm duplicated knowledge or responsibility before refactoring; normalized structural similarity can match code that should remain separate.
