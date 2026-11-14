# Selected finalization checks

Use this reference when `code-finalizer` selects changed-code coverage, Lean,
or mutation. Selection and limits are owned by
[the shared policy](quality-gates.md); these procedures do not select themselves.
Use the caller's fixed bases, complete task inventory, and absolute output paths.

## Changed-code unit coverage

When selected for finalization, require at least 90% unit-test coverage of the
changed executable code, unless the user or project specifies another threshold.
Honor stricter project requirements. This is not a universal coverage requirement
for every development increment.

Use a machine-readable report from the owning project's runner. Match its
executable locations to the current added/modified code against the captured
base, including new files. Use the project's differential coverage tool or a
deterministic parser.

Calculate `covered changed units / total changed executable units * 100`.
Prefer executable lines; if the report measures statements or instructions,
name that unit accurately. Report the raw counts and per-file gaps without
rounding a failing result up.

Exclude deleted lines, tests, comments, and genuinely generated/vendor code
with reasons. Investigate missing instrumentation and source entries rather
than removing them from the denominator. No executable changes means `skipped`,
not 100%. Integration coverage does not establish unit coverage.

## Lean properties

Follow [lean-verify](../../lean-verify/SKILL.md) for property selection, source
correspondence, toolchain, checker execution, and reporting. Select meaningful
bounds, state transitions, ordering, authorization, error handling, or data
preservation properties. A model must have an explainable correspondence to the
actual source.

Use the caller's fixed-base inventory and current file hashes to construct the
explicit scope manifest in its external evidence directory, following the
existing schema. Supply these inputs to the skill's proof construction and
`check.py`. Its default uncommitted scope omits checkpoint commits; `no_changes`
is not proof of the finalization scope.

Require checker evidence for the named theorems, reviewed hypotheses, and source
correspondence. Compilation alone, `sorry`, an assumed conclusion, or an unrelated
trivial theorem is insufficient. Retain proofs, hashes, reports, and checker
evidence. For non-Lean source, state that the proof checks a model, with its
assumptions and omitted semantics.

An unproved, stale, blocked, or incomplete selected property remains inconclusive.
Reproduce suspected bugs in the actual source before fixing them. Refresh the
proof and source correspondence when relevant inputs change.

## Mutation checkpoints

For `code-finalizer`, require a recorded commit and an empty
`git status --porcelain=v1 --untracked-files=all` before every mutation invocation,
including scans. Ignored build caches and external evidence do not require commits.
Never commit or stash unrelated work to satisfy this condition.

Use [mutator](../../mutator/SKILL.md) and the shared
[targeting and restoration procedure](change-scope.md#select-targets-without-broadening-the-gate).
Run one file at a time with explicit changed lines and fresh coverage. Require
per-site execution evidence, zero survivors, and zero unresolved execution errors.
Investigate apparent kills caused by infrastructure failures.

Complete exact source, test, index, and recovery-state restoration before applying
real fixes. After a fix, rerun the affected normal tests and build, then checkpoint
through the caller's named committer before another mutation invocation. Preserve
the caller's comparison base and refresh hashes and changed lines. A no-commit
restriction blocks a required new checkpoint; it does not invalidate an existing
matching clean checkpoint.
