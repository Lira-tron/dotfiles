---
name: crap4go
description: Install, configure, run, and interpret the crap4go CRAP-metric tool for Go code. Use for Go complexity-plus-coverage analysis, CRAP gates, or crap4go CLI questions.
---

# crap4go

Read [references/cli.md](references/cli.md) before running the tool.

Use [the shared change scope](../quality-gates/references/change-scope.md):
include unpushed commits and pending task edits, and gate only affected
functions. Already-upstream, unchanged code is excluded; empty scope is a skip.

Use `~/.agents/tools/quality-gates/bin/quality-tool ensure crap4go`, then invoke the exact path returned by `quality-tool path crap4go`.

Run from the owning Go module. Establish a passing test baseline, use the project's real coverage command, and cap analysis at four workers. `crap4go` reports scores but does not fail when a score is high; apply [the shared CRAP limit and conditional exception](../quality-gates/references/quality-gates.md) to the scoped results.
