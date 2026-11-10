# Mutator CLI and Python execution

Source: https://github.com/unclebob/mutator. The manager installs Crapper in the
same isolated environment because Mutator imports it but omits that dependency
from its package metadata. Check the installed `--help`.

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure mutator
mutator="$("$manager" path mutator)"
"$mutator" --root /path/to/project --scan --lines 12,18 src/example.py
"$mutator" --root /path/to/project --use-existing-coverage \
  --lines 12,18 --mutate-all --max-workers 4 --verbose \
  --test-command '/absolute/project/.venv/bin/python -m pytest tests/test_example.py' \
  src/example.py
```

Replace the example lines with current added/modified production lines from
the [shared inventory](../../quality-gates/references/change-scope.md).
Do not run either command with an empty inventory. Scan cannot be combined
with `--max-workers` or `--mutate-all`.

## Options and selection

- `--root PATH`: project root, custom-command cwd, and native output owner.
- `--source-root PATH` / `-s PATH`: repeatable discovery roots.
- `--changed`: Git-status files, not unpushed commits.
- Positional paths select files/trees; nonexistent paths become substring
  filters. Verify every explicit path and use one production file per run.
- `--scan`: list sites without tests, coverage generation, or snapshot writes.
- `--lines N,N,...`: positive source lines. It filters sites but does not
  independently disable history reuse.
- `--mutate-all`: bypass cached kills. **Combine with `--lines` for the Git-scoped
  gate**; the line filter still applies. Never omit it after tests change.
- `--since-last-run`: the default snapshot-based selection; incompatible with
  `--mutate-all` and not a replacement for the Git inventory.
- `--use-existing-coverage` / `--reuse-coverage`: read verified fresh reports.
- `--coverage-command CMD`: custom coverage command; failure propagates.
- `--no-coverage`: treat every site as covered. Diagnostic only; do not silently
  bypass missing coverage in a required gate.
- `--test-command CMD`: baseline and mutant command, executed relative to root
  in the original tree and mapped root in each worker.
- `--max-workers N`: default one per core; explicitly cap at four for execution.
- `--timeout-factor N`: baseline-time multiple; default `10`, minimum effective
  timeout two seconds.
- `--mutation-warning N`: advisory site-count warning, default `50`.
- `--verbose`: command and site progress. It does not retain all failed-mutant
  test output; reproduce suspect worker failures before accepting kills.

There is no `--update-manifest` or JSON-output flag.

## Python

Use the project's existing interpreter and pytest/unittest runner. Generate
LCOV as described in [Crapper's coverage guide](../../crapper/references/cli.md),
then run with `--use-existing-coverage`. Coverage XML/JSON alone is insufficient.

Pass an absolute **interpreter** path in `--test-command`, preserving its
virtualenv symlink, but use project-relative source and test paths. Worker
overlays omit `.venv` and `venv`; a relative `.venv/bin/python` command fails
there. Worker execution prepends worker source paths to `PYTHONPATH` and disables
bytecode writes. Verify that tests import the mutated copy rather than an
editable installation or an absolute source path in the original checkout.

Python mutations include boolean flips, comparison boundaries/equality,
arithmetic, `and`/`or`, removal of `not`/unary minus, and `0`/`1`.
Functions nested in another function are not independently selectable.

Other supported languages are Clojure, Java, Go, TypeScript/JavaScript, and Rust.
Use their actual build/test commands. Java defaults to Maven, Go to uncached
package tests, Rust to Cargo, and TypeScript/JavaScript to npm. A Brazil/Gradle
project requires verified native commands and compatible coverage; a language
being supported does not prove the default runner fits its build system.

## History, workers, and verdict

Snapshots are `.metrics/mutate/<namespace>.edn`. They contain per-site outcomes
and function hashes/counts; files in one namespace share a snapshot. Archive
the raw files rather than editing counts. Default history invalidates changed
function text, not changed tests, which is why scoped runs also use `--mutate-all`.
Both stdout `KILLED`/`SURVIVED` rows and summary/EDN counts can include retained
outcomes outside `--lines`. They are not the current execution inventory.
Use the selected-site messages and worker commands on **verbose stderr**, plus
runner evidence where needed, to verify which sites actually ran. Record fresh
execution counts separately from the cumulative report.

Workers live under `target/mutation-workers`. The selected source is copied;
many other project files are symlinked, so test side effects can still reach
the real tree. Old files under `target/mutator-backup/` are restored before a
non-scan run. Apply the shared snapshot/recovery checks.

Exit `0`: every executed mutant killed **or nothing executed**.
Exit `1`: usage error. Exit `2`: failed baseline or missing Crapper dependency.
Exit `3`: survivor. Coverage and other operational failures can propagate.

Nonzero mutant test exits, including compilation errors and timeouts, count as
killed. A missing executable or bad import in every worker can therefore give
false confidence. Check worker prerequisites and representative outcomes;
infrastructure failure is blocked evidence. Uncovered sites were not executed
and are not kills. Require current execution evidence for the selected sites.
