---
name: mutator
description: Run changed-line mutation testing for Python, Go, Java, TypeScript/JavaScript, Rust, and Clojure. Use for mutation scans, survivor hardening, or migration from mutate4go and mutate4java.
---

# Mutator

Read [the CLI and Python guide](references/cli.md) and
[the shared change scope and recovery rules](../quality-gates/references/change-scope.md).
Install with `~/.agents/tools/quality-gates/bin/quality-tool ensure mutator`;
the manager also installs its required Crapper dependency. Invoke the exact
path returned by `quality-tool path mutator`.

1. Capture the task's source, tests, index, and line inventory. Inspect
   `target/mutator-backup/` before execution: old backups can overwrite source.
2. Verify passing project tests and fresh compatible coverage. Use the actual
   project runner and interpreter; verify they also work in worker directories.
3. Scan one existing production file with `--scan --lines L1,L2,...`.
   Empty source/line scope skips execution.
4. Execute that file with **`--lines L1,L2,... --mutate-all`** and at most
   `--max-workers 4`. In this tool, the combination reruns every covered site
   on the explicit lines, including previously killed sites after test changes.
   `--lines` alone can still reuse historical kills.
5. Require all intended sites to execute, zero survivors, and no operational
   errors. Inspect uncovered sites and validate that reported kills came from
   mutant behavior, not a broken worker environment.
6. Archive logs and `.metrics/mutate/*.edn`, then verify source, tests, and index
   are unchanged and worker/recovery paths are clear. Follow the shared recovery
   rules on failure or interruption.

Mutator uses worker copies and EDN snapshots, not source-embedded manifests.
Exit `0` also covers nothing-to-run cases. Missing coverage, cached outcomes,
scan output, and counts from earlier runs cannot establish current acceptance.
