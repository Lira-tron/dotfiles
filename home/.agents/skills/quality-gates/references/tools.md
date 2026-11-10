# Tool usage

## Tool manager

The tracked manager is:

```text
~/.agents/tools/quality-gates/bin/quality-tool
```

It clones or updates official `github.com/unclebob` sources and installs executables into:

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
"$manager" ensure crapper dryer mutator
"$manager" ensure gherkin-parser gherkin-ir-dry-checker gherkin-mutator
"$manager" path mutator
```

Crapper, Dryer, and Mutator use separate Python 3.12 environments under the
manager's data `lib/` directory, created with `uv`; Python 3.11+ is the upstream
requirement. `ensure mutator` also installs Crapper in Mutator's environment
because its upstream package metadata omits that import dependency. Target
project test dependencies remain in the project's own environment. Parser
grammars may download on first use; an offline parser failure is a blocker.

The six old Go/Java executable names remain available only for existing legacy
integrations. Their skill entrypoints redirect to the maintained unified skills;
old command flags are not aliases for the new tools.

Run `<executable> --help` after installation and before relying on unfamiliar flags.

All CRAP, DRY, and mutation examples below require
[the captured change scope](change-scope.md). Substitute its selected
paths and actual current line numbers; `12,18` is only an example. Empty target
sets skip the gate. The tools' broad defaults do not define this policy.
For mutation, follow
[mutation artifact restoration](change-scope.md#mutation-artifacts-and-restoration)
after every invocation.

## Shared CRAP, DRY, and mutation tools

Use [`crapper`](../../crapper/SKILL.md), [`dryer`](../../dryer/SKILL.md), and
[`mutator`](../../mutator/SKILL.md) for supported languages, including Python,
Go, and Java. The [gate policy](quality-gates.md#required-checks) owns the
language-support boundary. Read each CLI guide for language-specific inputs.

```sh
"$manager" ensure crapper dryer mutator
crapper="$("$manager" path crapper)"
dryer="$("$manager" path dryer)"
mutator="$("$manager" path mutator)"
```

From the actual project root, after passing tests and generating verified fresh
coverage with its native runner:

```sh
"$mutator" --scan --lines 12,18 src/example.py
"$mutator" --use-existing-coverage --lines 12,18 --mutate-all \
  --max-workers 4 --verbose \
  --test-command '/absolute/project/.venv/bin/python -m pytest tests/test_example.py' \
  src/example.py
"$crapper" --use-existing-coverage --threshold 10 src/example.py
"$dryer" --edn src/example.py src/comparison.py
```

Replace paths, lines, and test commands from the captured scope and owning
configuration. Execute sequentially and stop to resolve a failed gate. Mutator
requires both the line filter and `--mutate-all` for fresh scoped execution.

Python uses coverage.py LCOV; see [the Python coverage example](../../crapper/references/cli.md#coverage-inputs).
Go uses a coverprofile; Java uses JaCoCo XML. Project-native commands can feed
these formats without forcing a Maven approximation onto a Brazil/Gradle package.
Use an absolute Python interpreter and relative test paths in worker commands.

Crapper and Dryer overwrite `.metrics/crap.edn` and `.metrics/dry.edn`.
Mutator writes `.metrics/mutate/*.edn` and temporary workers under `target/`.
Keep the real project as `--root`; archive native output into the external
feature directory after execution using the shared tool-output rules. Neither
`AI_ARTIFACT_ROOT` nor a shell `cd` redirects fixed output paths.

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
