# crap4go CLI

## Purpose

`crap4go` combines function cyclomatic complexity with statement-weighted Go coverage:

```text
CRAP = CC^2 * (1 - coverage)^3 + CC
```

It deletes `target/coverage/`, generates fresh coverage at `target/coverage/coverage.out`, analyzes non-test `.go` files while skipping `.git`, `target`, and `vendor`, and prints the worst scores first.

## Install and locate

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure crap4go
crap4go="$("$manager" path crap4go)"
```

## Syntax

```text
crap4go [options] [module-filter ...]
```

Arguments and options:

- `module-filter`: source-path substring. Multiple filters include files matching any filter.
- `-h`, `--help`: print usage and exit.
- `--max-workers N`: parallel source-analysis workers. `N` must be positive; default is half the logical CPUs. Use at most `4` for the default quality gate.
- `--test-command COMMAND`: coverage-producing test command. Default is `go test ./...`.
  - If `COMMAND` contains `{coverprofile}`, that token becomes `-coverprofile=target/coverage/coverage.out`.
  - Otherwise the coverage flag is appended to the command.

Examples:

For the quality gate, select explicit source paths and filter affected
functions using [the change scope](../../quality-gates/references/change-scope.md).
Do not invoke the pathless whole-module default when that scope is empty.

```sh
"$crap4go" --max-workers 4 internal/service/changed.go
"$crap4go" --max-workers 4 \
  --test-command 'go test -tags appunit ./internal/app {coverprofile}' \
  internal/app/changed.go
```

## Output and exit behavior

The report contains function, package, cyclomatic complexity, coverage, and CRAP columns. Missing function coverage is shown as `N/A`.

- Exit `0`: analysis completed, regardless of score.
- Exit `1`: invalid arguments, test/coverage failure, unreadable profile, or analysis error.

Therefore a zero exit code is not the quality verdict. Parse the report and fail the gate when any in-scope function exceeds the selected threshold.
