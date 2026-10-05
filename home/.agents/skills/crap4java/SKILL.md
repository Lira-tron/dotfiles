---
name: crap4java
description: Install, run, and interpret crap4java CRAP analysis for Maven-based Java code. Use for Java complexity-plus-JaCoCo coverage analysis, changed-file CRAP gates, or crap4java CLI questions.
---

# crap4java

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md),
including unpushed commits and pending task edits.
Pass explicit selected files and gate only affected methods; do not assume
`--changed` covers unpushed commits or every staged/untracked input. Empty scope is a skip.

Run from the correct Maven workspace or module and establish a passing baseline. This tool invokes Maven and JaCoCo itself; do not use it as a Brazil-package substitute when Maven is not the owning build system.

The shared tool manager applies a local patch so the executable's built-in CRAP
threshold is `10.0`. Record its actual exit status
separately from [the shared CRAP policy](../quality-gates/references/quality-gates.md);
a scoped policy verdict must not hide a tool failure or missing coverage.
