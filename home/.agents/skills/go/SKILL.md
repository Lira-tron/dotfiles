---
name: go
description: Finalize an implementation when the user invokes /go or $go. Build with bbr, enforce new-code unit coverage and CRAP, commit, simplify, run overall code review, assess DRY, verify properties with Lean 4, and run mutation testing only from committed checkpoints. Not a trigger for Go-language questions or ordinary approval.
---

# Go — finish the implementation

If the request is "implement X /go", implement X first, then execute this
workflow. Read the gates early enough to design testable, simple code. Run the
workflow only when requested; an ordinary "go ahead" is not an invocation.

Invocation authorizes scoped local fixes and checkpoint commits through the
`commit` skill's named committer. Honor an explicit no-commit or review-only
restriction: report the affected gates as blocked and do not run mutation on
uncommitted code. Do not push, amend, rewrite history, create a CR, or use Git
worktrees. This skill changes the local implementation; it does not deploy it.

## Establish scope and evidence

Read the repository instructions and identify every owning package. Use
[the shared change scope](../quality-gates/references/change-scope.md):
unpushed commits plus staged, unstaged, and relevant untracked task edits.
Fetch first, verify the actual tracked upstream, and record its merge base
with HEAD. Do not assume `origin/mainline`, guess `HEAD~1`, or substitute an
older goal base. Ask for an explicit base if the upstream boundary cannot be
established; never default to the whole repository.

Record the base revision, original goal, target paths, staged/unstaged changes,
relevant untracked files, and renamed/deleted paths in a run directory outside
the repository. Keep logs and proof artifacts there. **Keep the comparison base
fixed across commits** and update the in-scope line/function inventory as fixes
change the code. A clean working tree after a checkpoint does not mean the
implementation disappeared.

Preserve unrelated work. Never commit or stash someone else's changes just to
make the mutation precondition pass. Track each gate as `passed`, `failed`,
`blocked`, or `not applicable`, with commands and evidence tied to the source
and test versions examined. Missing evidence is not a pass.

Read [the gate details](references/gates.md) before choosing coverage, CRAP, DRY,
Lean, or mutation commands. Use the installed language skills and project test
configuration. Do not run the entire `quality-gates` workflow as a nested step:
its mutation order does not supply this workflow's required commit checkpoints.

All gates use this captured local-change scope. Keep the comparison base across
checkpoint commits and refresh the inventory for scoped fixes. Local committed
work remains eligible until it is upstream; an empty working-tree diff alone
does not make a gate `not applicable`. If the applicable local-change scope is
empty, report the gate as `not applicable`.

## 1. Build with bbr

From each changed Brazil package, resolve and run the user's `bbr` command.
It is currently a zsh alias for `eda br`; interactive zsh loads that alias:

```sh
zsh -ic 'setopt pipefail; bbr'
```

Capture the complete log and actual exit code. Fix build or unit-test failures,
then rerun until green. A compile-only command cannot stand in for the owning
package's release checks. If `bbr` is unavailable, investigate its configuration
and report the blocker rather than silently claiming another command was `bbr`.
Outside Brazil, use the project's real build-and-test command and name the
substitution.

## 2. Enforce unit coverage and CRAP

Generate fresh unit-test coverage. Require **at least 90% coverage of the new
and modified executable code**, measured against the fixed goal scope, not the
whole-package average. Add meaningful tests for uncovered behavior; never hide
executable lines or weaken assertions to increase the score.

Apply [the shared CRAP policy](../quality-gates/references/quality-gates.md)
only to affected functions in the captured change scope: normally
**CRAP <= 8**, with its documented single-question conditional exception.
Preserve stricter project limits and report stricter tool failures separately.
Improve tests or simplify the actual responsibility when this gate fails.
Rerun the affected checks and `bbr` after edits before committing.

## 3. Commit the validated implementation

Invoke `commit`, delegating grouping, staging, and commits to the named
committer. Provide the goal's exact scope and build/coverage/CRAP evidence.
The coordinator never runs `git add` or `git commit`. Record the returned hashes
and inspect Git status. If the implementation is already committed, record the
existing checkpoint instead of creating an empty commit.

## 4. Run simplify

Run the `simplify` skill on the **whole goal change from the recorded base**,
including the checkpoint commits. Do not supply only the now-empty uncommitted
diff. In Codex, keep orchestration in a session that can launch simplify's
native reviewers; in Claude Code, invoke its `/simplify` capability.

Apply useful improvements within scope. If code or tests change, rerun build,
unit coverage, and CRAP before advancing. Simplify itself does not commit.

## 5. Run overall code review

Invoke `overall-code-review` with the same complete goal scope, current local
code, and recorded comparison base. Follow that skill's `edrevn` workflow and
require `.codex/reviews/OverallReview.md`.

Assess all action items, especially blockers, majors, and architectural
feedback. Apply warranted fixes and retain a reason for every item left
unfixed. A confirmed, in-scope, unresolved blocker or major prevents completion;
a documented false positive is not an unresolved defect.

## 6. Check DRY, verify Lean properties, and checkpoint

Run `dry4go` for Go or `dry4java` for Java and investigate candidates involving
the captured changed functions, comparing with relevant existing source and
tests. Consolidate duplicated knowledge or responsibilities where justified.
Record why incidental similarity remains separate. Do not gate or refactor
unchanged-versus-unchanged pairs. For agent instructions, prefer references to
shared rules over copying the same policy into multiple workflows.

Use `lean-verify` to establish and check meaningful properties of the goal's
current code. Supply the persisted goal scope explicitly; a default
`uncommitted` run after a commit can return `no_changes` and is not verification.
Follow the scope and checker procedure in the gate details.

After review, DRY, or proof-driven fixes, rerun build, unit coverage, CRAP, and
affected DRY/proof checks. Revisit simplify or overall review when new production
changes materially alter their conclusions. Do not reuse evidence from older
source or tests.

Once these gates pass, use the committer to commit all remaining in-scope
source, tests, and versioned task artifacts, including review reports when
repository policy permits them. Record this checkpoint. Required checks that
remain failed, unproved, or unsupported prevent an all-passed result.

## 7. Mutation-test committed code

Before **every mutation execution**, require a valid recorded checkpoint and
an empty `git status --porcelain=v1 --untracked-files=all`. Ignored build caches
and external evidence do not need commits. Unrelated dirty work blocks mutation;
do not include it in a commit without authorization.

Before any tool invocation, including a scan, resolve and retire active recovery
backups as described in the gate details. A clean Git status alone cannot detect
an ignored backup that the tool could restore over newer code.

Run the appropriate mutation tool one source file at a time, using explicit
`--lines` from the captured change scope, fresh coverage, and the owning
package's real tests. Manifest-based defaults do not establish Git scope.
Keep build, coverage, CRAP, DRY, Lean, and mutation checks sequential. Use at most four
mutation workers where supported. Follow the gate details for result parsing,
manifest handling, and restoration checks.

Require zero survivors and zero unresolved execution errors. If a run exposes
missing assertions or a source bug, restore the normal code, fix it, rerun the
affected gates and `bbr`, then commit **before the next mutation execution**.
Recheck the affected mutation sites even when only tests changed; an unchanged
source manifest must not turn that rerun into a zero-site pass.

After each invocation, inspect the diff against its checkpoint. Restore any
identified residual mutant before validation or commits. Preserve tool-written
manifests; validate and commit legitimate manifest changes through the committer
before running mutation on the next file. Never commit mutated program logic.

## 8. Verify the final state and report

Verify that normal source is restored and every gate's evidence covers the final
source and tests. Refresh affected checks when code, tests, manifests, or source
hashes changed; do not invent a pass from a clean Git status. Run final `bbr`
when changes since the last passing build require it.

Use the committer for any remaining validated task changes. Finish with a clean
task working tree and record the final checkpoint hashes. If unrelated work or
an unavailable check prevents completion, report the exact limitation.

Write a concise summary in the external run directory and report its path,
the overall review path, commits, build result, changed-code coverage numerator
and denominator, maximum in-scope CRAP, DRY dispositions, mutation results, and
Lean proof status/assumptions. List unresolved issues first. Claim completion
only when all required gates pass or have a justified applicability exclusion;
an explicit user waiver must be reported as a waiver, not a passed check.
