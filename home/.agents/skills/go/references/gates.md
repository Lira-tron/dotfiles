# Gate details

Use the project's actual build system and unit-test boundaries. Read the matching
tool skill and its CLI reference before execution. Missing or incompatible
tooling blocks a required gate; a successful unrelated command is not a substitute.

All gates use
[the shared change-scope procedure](../../quality-gates/references/change-scope.md):
unpushed commits plus staged, unstaged, and relevant untracked task edits,
compared with the recorded merge base against the fetched upstream. Preserve
that base across `/go` commits. An empty applicable scope is `not applicable`,
not a pass or a reason to analyze already-upstream code.

## Unit coverage: at least 90% of changed executable code

Use a machine-readable unit-coverage report, such as JaCoCo XML, LCOV, coverage
XML/JSON, or a Go coverage profile. Resolve its source paths against the owning
package. Match executable locations to the current added/modified code relative
to the recorded upstream merge base, including new files. Use a deterministic parser or the
project's existing differential coverage tool, not estimates from filenames.

Calculate `covered changed units / total changed executable units * 100`.
Prefer executable lines; if the tool measures statements or instructions instead,
report that unit explicitly and do not relabel it line coverage. Report the raw
counts and per-file gaps; do not round a value below 90% up to a pass.

Exclude deleted lines, tests themselves, comments, and genuinely generated/vendor
code with reasons. Missing instrumentation or missing source entries must be
investigated, not silently removed from the denominator. No executable changes
means `not applicable`, not 100%. Branch coverage is useful additional evidence;
do not replace the requested changed-code measurement with a package-wide total.

Use unit-test results for this threshold. Integration-only coverage does not
demonstrate unit coverage. Add assertions for real success, failure, boundary,
and state-transition behavior rather than tests that merely execute code.

## CRAP: per-function maximum, not an average

Use `crap4go` or `crap4java` via the shared manager:

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure crap4go
"$manager" path crap4go
```

Select the language-appropriate tool and explicit current source paths from
the captured change inventory. After checkpoints, keep those explicit
paths instead of rediscovering an empty `--changed` set. Filter generated code
and unaffected functions from the gate.

CRAP combines cyclomatic complexity and coverage:
`CC^2 * (1 - coverage)^3 + CC`. Apply
[the shared limit and conditional exception](../../quality-gates/references/quality-gates.md).
Upstream `crap4go` describes 30+ as high risk; that is not this workflow's
acceptance threshold. `crap4java` enforces the same built-in ceiling of 8:
retain its actual exit status and distinguish it from the scoped policy
verdict. Do not label a tool failure as a successful run.

Evaluate unrounded scores: `crap4go` can exit successfully with scores above
the limit and prints rounded scores and coverage. For example, CC=8 and 95%
coverage give CRAP=8.008, which can display as 8.0 but fails the ceiling of 8.
Use verified unrounded output, or deterministically recompute from exact
complexity and raw function coverage counts. Do not infer a pass from rounded
display values. Missing coverage, `N/A`, zero selected functions despite
executable changes, or a failed coverage command cannot yield a passing gate.

The Java tool invokes Maven and has no custom test-command option. Do not run it
as an approximation for a Brazil/Gradle package. Use a verified project-native
equivalent with the same metric and source scope, or report the incompatibility.

## DRY: decisions about duplicated responsibilities

Load `dry4go` or `dry4java` and scan relevant package source and tests, including
existing code needed for comparison. Skip generated output and dependency caches.
Only pairs with at least one affected function/declaration from the captured
change inventory belong to the gate. Exclude unrelated pairs from its
result and fixes.

The tools normalize syntax and default to a similarity threshold of 0.82.
This is a candidate-detection threshold, not a quality score to force below 0.82.
Do not raise it or suppress matches to obtain an empty report.

Record each candidate's two locations and disposition: consolidated, already
shared, incidental similarity, or unresolved harmful duplication. A zero process
exit does not mean no candidates were found. Harmful duplication left unresolved
blocks this gate; justified separate implementations do not.

## Lean 4: checked properties with explicit limits

Follow `lean-verify` for property selection, source correspondence, the pinned
toolchain, proof checking, and its report contract. Verify meaningful invariants
from the requested behavior: bounds, state transitions, ordering, authorization,
error handling, or preservation of data. Track relevant unchanged dependencies
as context without claiming the entire repository has been verified.

Use the recorded upstream-base inventory and current file hashes to construct
the explicit scope manifest used by the report. Follow the existing manifest
schema rather than adding unsupported `--base` or `--files` flags to `scope.py`.
Its `--mode uncommitted` covers only pending edits, so it is insufficient when
unpushed commits exist. Refresh the manifest after scoped fixes, preserving
previous snapshots. Use the same proof construction and documented `check.py`
on these explicit inputs. Do not invoke `--mode all` to bypass an empty
working-tree diff or call `no_changes` a Lean pass.

Require checker evidence for the actual named theorems, with reviewed hypotheses
and source correspondence. Compilation alone, `sorry`, an assumed desired
conclusion, or a trivial theorem unrelated to the change is insufficient.
Retain proofs, source hashes, reports, and checker evidence outside the repository
unless the package already owns such artifacts.

For other languages, Lean checks an explicitly described model; it does not
automatically prove the source implementation. State assumptions and omitted
semantics. Unproved, blocked, stale, or incomplete relevant properties leave the
gate inconclusive. Reproduce suspected bugs against the actual source before
fixing them. Rerun affected proofs and refresh correspondence after fixes.
Use `not applicable` only when the scope genuinely contains no relevant behavior,
with a concrete explanation.

## Mutation: clean checkpoints and nonempty evidence

Load `mutate4go` or `mutate4java`. Read its CLI reference and preserve its embedded
manifests. Use the real focused test command and fresh coverage. The Java custom
test-command path may not generate coverage; supply verified compatible coverage
or explicitly account for the tool's lack of coverage filtering.

Before any invocation, inspect the tool's active recovery paths. In the installed
Go tool, `<source-file>.mutate4go.bak` is restored over the source before even
`--scan` executes, and restoration does not itself retire the backup. Compare
any backup and current source with the recorded checkpoint before allowing the
tool to run. After verified recovery, archive the backup outside the repository
and ensure its active path is absent so a later invocation cannot overwrite a
newer fix. Inspect the Java tool's recovery behavior when applicable; do not
invent a matching filename. If recovery or ownership is uncertain, stop.

Scan the selected source and record the intended sites before execution.
Always use explicit `--lines` for current added/modified source lines in the
captured change scope. The default manifest comparison and
`--since-last-run` do not select unpushed Git changes; do not use either as a
scope selector or combine them with `--lines`. Never omit the selector when
the line set is empty. Test-only or deletion-only changes do not authorize
mutation of unchanged source.

Update line mappings after scoped fixes. Rerun prior survivors and affected
sites in the captured inventory when tests change; a stored manifest must not
skip them. Do not use `--update-manifest` to pretend mutation testing occurred.

- Go requires `Survived: 0` and no operational error; exit 0 alone is insufficient.
- Java requires exit 0 plus evidence that the intended sites actually ran.
- Review every skipped/uncovered site. Add tests for relevant executable gaps;
  skipped sites are not killed mutants. A zero-site run is `not applicable` only
  when the scoped behavior has no supported mutation sites and that is verified.
- Investigate timeouts: do not treat an infrastructure stall as evidence that a
  mutant was killed by the tests.

Before each execution, record the clean checkpoint and source/test hashes.
Afterward, compare the resulting source with that checkpoint, including failure
and interruption paths. Expected embedded manifest updates are different from
residual mutated logic. Preserve manifests and archive tool backups outside
their active recovery paths after verified recovery. Undo only positively
identified residual mutations; do not use blanket resets or overwrite concurrent
user edits. If ownership or restoration is uncertain, stop mutation and report
the checkpoint, affected files, and recovery evidence.

After restoration, verify the normal tests/build before the committer commits
legitimate manifests or fixes. Every next execution must again start clean.
Changes to tests invalidate affected mutation results even when production
source is unchanged. Keep logs and the executed-site inventory so a retry cannot
hide an earlier survivor behind an unchanged-source shortcut.

## Sources and local policy

The threshold of 8 follows the shared `quality-gates` policy. Tool contracts
above were checked against the installed per-tool skills and their CLI references.
The upstream metric descriptions are maintained in:

```text
https://github.com/unclebob/crap4go
https://github.com/unclebob/crap4java
https://lean-lang.org/doc/reference/latest/ValidatingProofs/
```
