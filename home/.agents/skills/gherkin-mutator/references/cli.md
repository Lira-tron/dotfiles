# gherkin-mutator CLI

## Install and prerequisites

Select the APS mutation workflow and feature scope using [the shared policy](../../quality-gates/references/quality-gates.md#test-workflow).

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure gherkin-mutator
gherkin_mutator="$("$manager" path gherkin-mutator)"
```

Before running:

- The feature parses successfully.
- Generated acceptance entrypoints exist.
- A Go- or Java-specific persistent runner adapter implements the APS newline-delimited JSON protocol.
- The ordinary acceptance baseline passes.

## Syntax and options

```text
gherkin-mutator [options]
```

- `--feature PATH`: feature to mutate. Default `features/a-feature.feature`.
- `--work-dir PATH`: mutation work files. Default `build/acceptance-mutation`.
- `--generated-dir PATH`: generated acceptance tests. Default `<work-dir>/generated`.
- `--workers N`: maximum persistent runner processes. Default `1`; use at most `4`.
- `--timeout DURATION`: full-run timeout, using Go duration syntax such as `30s` or `5m`.
- `--status-interval DURATION`: periodic status interval. Default `30s`; `0` disables periodic status.
- `--level full|hard|soft`: differential reuse level. Default `hard`.
- `--runner-worker COMMAND`: required persistent adapter command.
- `--implementation-hash HASH`: override the generated acceptance implementation hash.
- `--json`: emit the final report as JSON instead of text.

Levels:

- `full`: ignore stamps/manifests and execute every mutation.
- `hard`: reuse only when feature identity, scenario, background, and generated implementation hash match.
- `soft`: like hard, but may reuse when generated implementation changed.

Use `hard` for the default quality gate. Do not use `full` merely to bypass a manifest.

Example:

```sh
"$gherkin_mutator" \
  --feature features/login.feature \
  --generated-dir build/acceptance/generated \
  --runner-worker './build/acceptance/runner-worker' \
  --workers 4 \
  --level hard \
  --status-interval 10s \
  --json
```

## Persistent runner protocol

The mutator starts up to `--workers` long-lived adapter processes. Each stdin line is a JSON job:

```json
{"id":"m1","feature_json":".../feature.json","generated_dir":"...","work_dir":"...","timeout":"30s"}
```

Each stdout line must be one JSON response:

```json
{"id":"m1","outcome":"test_failure","output":"...","error":"","duration":125000000}
```

The adapter must:

- Keep running for multiple jobs.
- Write only protocol JSON to stdout.
- Write diagnostics to stderr.
- Execute generated acceptance tests against the supplied mutated feature IR.
- Return the same job id.

An ordinary shell command that reruns tests once is not a valid adapter.

## Results, manifests, and exits

- `killed`: altered example behavior was detected.
- `survived`: acceptance checks accepted the altered behavior.
- `error`: mutation or runner execution failed.

Successful results update the scenario manifest and feature mutation stamp. Never edit either manually.

- Exit `0`: zero survivors and zero errors.
- Exit `1`: survivor, mutation/runner error, input error, or report-write failure.
- Exit `2`: invalid flags, level, duration, or missing required runner.

Report inapplicable runs as skipped under the shared policy. Missing prerequisites for an applicable APS run are blocked; completed runs require zero survivors and errors.
