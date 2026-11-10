---
name: dryer
description: Find structural duplicate candidates in Python, Go, Java, TypeScript, Rust, and Clojure. Use for DRY analysis or migration from dry4go and dry4java.
---

# Dryer

Read [the CLI guide](references/cli.md), then install with
`~/.agents/tools/quality-gates/bin/quality-tool ensure dryer`.
Invoke the exact path returned by `quality-tool path dryer`.

Follow [the shared change scope](../quality-gates/references/change-scope.md).
Pass explicit existing source files and relevant comparison files; include tests
explicitly when relevant. Retain only pairs involving an affected declaration.
An empty task scope is a skip, not a request for a whole-project gate.

Apply [the shared DRY policy](../quality-gates/references/quality-gates.md).
Each match is a candidate: inspect both locations and decide whether they
duplicate knowledge or responsibility. Record the disposition. Exit `0` does
not mean there were no candidates or that every source parsed successfully.

Archive the report, stderr, and `.metrics/dry.edn` under the selected external
feature directory. Keep the project's root as `--root`; it controls source
identity as well as native output placement.
