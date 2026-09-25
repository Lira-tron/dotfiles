# Tool usage

## Tool manager

The tracked manager is:

```text
~/.agents/tools/quality-gates/bin/quality-tool
```

It clones or updates official `github.com/unclebob` sources and builds executables into:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/agent-tools/quality-gates/bin
```

Source and build caches live under:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/agent-tools/quality-gates/src
```

Set `QUALITY_GATES_DATA_HOME` or `QUALITY_GATES_CACHE_HOME` to override the complete data or cache root. These dedicated variables take precedence over XDG settings.

Examples:

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" list
"$manager" ensure crap4go mutate4go dry4go
"$manager" ensure gherkin-parser gherkin-ir-dry-checker gherkin-mutator
"$manager" path mutate4go
```

Run `<executable> --help` after installation and before relying on unfamiliar flags.

All CRAP, DRY, and mutation examples below require
[the captured change scope](change-scope.md). Substitute its selected
paths and actual current line numbers; `12,18` is only an example. Empty target
sets skip the gate. The tools' broad defaults do not define this policy.

## Go

Load the `crap4go`, `mutate4go`, or `dry4go` skill for complete current arguments and exit semantics.

Install:

```sh
"$manager" ensure crap4go mutate4go dry4go
```

Typical commands:

```sh
crap4go --max-workers 4 --test-command 'go test ./...' path/to/file.go
mutate4go path/to/file.go --scan
mutate4go path/to/file.go --lines 12,18 --max-workers 4 --verbose
dry4go --format json path/to/file.go path/to/comparison.go
```

Use the project's real focused test command with `--test-command` when `go test ./...` is not the correct coverage or mutation boundary. Explicit `--lines` selects Git changes; do not substitute manifest-based defaults, `--since-last-run`, or `--mutate-all`.

## Java

Load the `crap4java`, `mutate4java`, or `dry4java` skill for complete current arguments and exit semantics.

Install:

```sh
"$manager" ensure crap4java mutate4java dry4java
```

Typical commands:

```sh
crap4java path/to/File.java
mutate4java path/to/File.java --scan
mutate4java path/to/File.java --lines 12,18 --max-workers 4 --verbose
dry4java --format edn path/to/File.java path/to/Comparison.java
```

Run from the owning Java or Maven module. In a Brazil workspace, first identify the owning package and its focused test command; do not run a workspace-root Maven approximation. Preserve manifests written by the selected-line run; never initialize them with an unscoped mutation command or hand editing.

## Gherkin/APS

Select applicability using [the shared test workflow policy](quality-gates.md#test-workflow) before installing APS tools. The project-specific generator, runtime, and handlers are described in [the execution guide](gherkin.md); they are not installed by the commands below.

Load the `gherkin-parser`, `gherkin-ir-dry-checker`, or `gherkin-mutator` skill for complete current arguments and protocol details.

Install the official Go fallback binaries:

```sh
"$manager" ensure gherkin-parser gherkin-ir-dry-checker gherkin-mutator
```

The manager also exposes `ir-dry-checker` as an alias for `gherkin-ir-dry-checker`.

Typical commands:

```sh
gherkin-parser features/example.feature build/acceptance/example.json
gherkin-ir-dry-checker build/acceptance/example.json build/acceptance/example.dry.json
gherkin-mutator \
  --feature features/example.feature \
  --runner-worker './path/to/persistent-runner-adapter' \
  --workers 4 \
  --level hard \
  --status-interval 10s \
  --json
```

The runner adapter is project-specific and mandatory. Do not substitute a command that merely reruns tests without implementing the APS persistent worker protocol.
