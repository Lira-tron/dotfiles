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

Use the [Crapper skill](../../crapper/SKILL.md) for supported languages,
including Python, Go, and Java. Install through the shared manager and pass
explicit existing source paths from the captured inventory. Keep that selection
after checkpoints; `--changed` omits unpushed commits.

Apply [the shared CRAP limit and conditional exception](../../quality-gates/references/quality-gates.md)
to affected functions only. `--threshold 10` compares full-precision scores
across every function in the selected files; retain its actual exit separately
from the scoped verdict. The text table rounds to one decimal and EDN to four.
Use the source-aware, unrounded API or raw coverage counts described in Crapper's
CLI guide when filtering individual functions or deciding a boundary value.

Generate coverage through the owning project's runner first. Python requires
coverage.py LCOV; Go uses a coverprofile and Java uses JaCoCo XML. Verify success,
freshness, and source mapping before `--use-existing-coverage`. Missing coverage,
`N/A`, empty results despite executable changes, or a failed coverage command
cannot yield a pass, even if Crapper exits successfully.

## DRY: decisions about duplicated responsibilities

Load `dryer` and scan relevant package source and tests, including
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
the explicit scope manifest under `.ai/go/<run-id>/lean/`, following the existing
manifest schema. Supply this directory and manifest to `lean-verify` instead of
its standalone external-directory setup. Do not invoke `scope.py` here: it
rejects in-repository output, and its `--mode uncommitted` omits checkpoint
commits. Refresh the manifest after scoped fixes, preserving previous snapshots.
Use the same proof construction and documented `check.py` on these explicit
inputs. Do not invoke `--mode all` to bypass an empty working-tree diff or call
`no_changes` a Lean pass.

Require checker evidence for the actual named theorems, with reviewed hypotheses
and source correspondence. Compilation alone, `sorry`, an assumed desired
conclusion, or a trivial theorem unrelated to the change is insufficient.
Retain proofs, source hashes, reports, and checker evidence in
`.ai/go/<run-id>/lean/`.

For other languages, Lean checks an explicitly described model; it does not
automatically prove the source implementation. State assumptions and omitted
semantics. Unproved, blocked, stale, or incomplete relevant properties leave the
gate inconclusive. Reproduce suspected bugs against the actual source before
fixing them. Rerun affected proofs and refresh correspondence after fixes.
Use `not applicable` only when the scope genuinely contains no relevant behavior,
with a concrete explanation.

## Mutation: clean checkpoints and nonempty evidence

Load [Mutator](../../mutator/SKILL.md) and its CLI reference, and follow
[the shared recovery policy](../../quality-gates/references/change-scope.md#mutation-artifacts-and-restoration).
Use the actual project test command and fresh compatible coverage. Verify that
the same command can run against worker copies; for Python use the project
interpreter's absolute path and relative source/test paths.

Before every invocation, record the clean checkpoint and source/test hashes,
then inspect `target/mutator-backup/`. Resolve and archive legacy backups before
a non-scan run can overwrite current source. Mutator now writes EDN snapshots
under `.metrics/mutate/` and runs copied sources under `target/mutation-workers/`.
It does not add source comments.

Scan one selected file with explicit `--lines`. Execute using
`--lines L1,L2,... --mutate-all --max-workers 4` so Git lines remain the boundary
and historical kills cannot suppress a rerun after tests change. The scan does
not accept `--max-workers` or `--mutate-all`. Empty production line scope skips
mutation; never widen it to obtain a nonempty result.

Require current per-site execution evidence, zero survivors, and no operational
errors. Exit 0 also covers nothing-to-run cases. Review uncovered sites and
worker prerequisites: compilation errors, missing dependencies, and timeouts
can all be counted as kills by the tool. Reproduce suspect failures; an
infrastructure error is not test-strength evidence.

Archive raw EDN, logs, and recovery evidence in the external run directory.
Verify source, tests, and index match the checkpoint and workers/backups are
clear before applying fixes. Follow native-output retention rules, then verify
normal tests/build before authorized checkpoint commits. Refresh coverage and
rerun selected sites after test changes without changing the upstream base.

## Sources and local policy

The threshold of 10 follows the shared `quality-gates` policy. Tool contracts
above were checked against the installed per-tool skills and their CLI references.
The upstream metric descriptions are maintained in:

```text
https://github.com/unclebob/crapper
https://github.com/unclebob/dryer
https://github.com/unclebob/mutator
https://lean-lang.org/doc/reference/latest/ValidatingProofs/
```
