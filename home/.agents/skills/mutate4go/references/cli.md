# mutate4go CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure mutate4go
mutate4go="$("$manager" path mutate4go)"
```

```text
mutate4go <source-file.go> [options]
```

Exactly one existing Go source file is required.

## Options

- `--scan`: report total and changed mutation-site counts without tests, coverage, mutation, or manifest writes.
- `--update-manifest`: rewrite the embedded manifest without tests, coverage, or mutation.
- `--reuse-coverage`: reuse `target/coverage/coverage.out`; fail if it does not exist. The result may be stale.
- `--reuse-lcov`: accepted compatibility alias for `--reuse-coverage`.
- `--lines L1,L2,...`: mutate only positive source-line numbers.
- `--since-last-run`: mutate only functions changed relative to the embedded manifest.
- `--mutate-all`: ignore the manifest and mutate every covered site. Do not use for the default differential gate.
- `--mutation-warning N`: warn above `N` discovered sites; default `50`. This is advisory.
- `--timeout-factor N`: mutant timeout as a positive multiple of baseline duration; default `10`, minimum effective timeout one second.
- `--test-command CMD`: baseline and mutant command; default `go test ./...`.
- `--max-workers N`: isolated parallel workers. Default `0`, which runs serially. Use at most `4`.
- `--verbose`: print operation and worker progress to stderr.
- `--help`: print usage.

Selection modes conflict: do not combine `--scan` or `--update-manifest` with mutation-execution selection; do not combine `--lines`, `--since-last-run`, and `--mutate-all` with each other.

## Differential behavior

- No manifest: normal execution mutates all covered sites.
- Existing manifest: normal execution automatically selects changed functions.
- `--scan` never changes the manifest.
- Normal execution writes the updated embedded manifest. Never edit it manually.
- An interrupted run keeps a backup that the next run attempts to restore.

Supported mutations include `0`/`1`, booleans, arithmetic `+ - * /`, comparisons, equality, and `&&`/`||`.

## Recommended sequence

Capture [the change scope](../../quality-gates/references/change-scope.md)
first. Replace the example line numbers below with its current added/modified
production lines. Do not execute mutation if that set is empty.

```sh
"$mutate4go" path/to/file.go --scan
"$mutate4go" path/to/file.go \
  --lines 12,18 \
  --test-command 'go test ./internal/owner' \
  --max-workers 4 \
  --verbose
```

Fresh coverage is generated unless `--reuse-coverage` is selected. Uncovered sites are skipped and must be reviewed as a coverage gap.

## Output and exit behavior

Statuses are `killed`, `survived`, and `timeout`; timeouts are counted as killed in the report.

- Exit `0`: command completed—even if survivors are present.
- Exit `1`: usage, baseline, coverage, worker, filesystem, or other operational failure.

The quality gate must inspect `Survived:` and require zero.
