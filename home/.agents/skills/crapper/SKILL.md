---
name: crapper
description: Run CRAP complexity and coverage analysis for Python, Go, Java, TypeScript/JavaScript, Rust, and Clojure. Use for CRAP gates or migration from crap4go and crap4java.
---

# Crapper

Use Crapper for CRAP analysis across its supported languages. Read
[the CLI and coverage guide](references/cli.md) before execution and follow
[the shared change scope](../quality-gates/references/change-scope.md) and
[CRAP policy](../quality-gates/references/quality-gates.md).

1. Install with `~/.agents/tools/quality-gates/bin/quality-tool ensure crapper`.
   Invoke the exact path returned by `quality-tool path crapper`.
2. Run the owning project's tests and generate fresh compatible coverage with
   its existing runner. Verify the command succeeded and the report maps to
   the selected source. Prefer `--use-existing-coverage` after that verification.
3. Pass explicit existing source files from the captured scope. Gate affected
   functions only. `--changed` uses Git status and omits unpushed commits.
4. Apply the shared per-function limit and conditional exception. `--threshold 10`
   compares unrounded scores, but covers every reported function in selected
   files. Preserve its exit status separately from the affected-function verdict.
5. Archive stdout, stderr, the coverage evidence, and `.metrics/crap.edn` in the
   selected external feature directory. Preserve native paths during execution.

Missing coverage can produce a numeric score at 0% coverage and exit successfully.
That is blocked evidence, not a passing gate. Complexity-only output, empty
results despite executable changes, and ambiguous function identity also cannot
establish a pass. Read the CLI guide for exact-score and source-identity limits.
