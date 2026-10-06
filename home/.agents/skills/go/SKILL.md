---
name: go
description: Finalize an implementation when the user invokes /go or $go. Build with bbr, enforce new-code unit coverage and CRAP, commit, simplify, run reviewers in parallel, resolve their findings, assess DRY, verify properties with Lean 4, and run mutation testing only from committed checkpoints. Not a trigger for Go-language questions or ordinary approval.
---

# Go — finish the implementation

If the request is "implement X /go", implement X first, then execute this
workflow. Read the gates early enough to design testable, simple code. Run the
workflow only when requested; an ordinary "go ahead" is not an invocation.

Invocation authorizes scoped local fixes and checkpoint commits through the
`commit` skill's named committer. Honor an explicit no-commit or review-only
restriction: report the affected gates as blocked and do not run mutation on
uncommitted code. Do not push, amend, rewrite history, or create a CR.
Read `~/.agents/skills/worktree/SKILL.md` and reuse this task's worktree; transfer
existing work through that procedure if necessary. This skill changes the local
implementation; it does not deploy it.

## Establish scope and evidence

Read the repository instructions and identify every owning package. Use
[the shared change scope](../quality-gates/references/change-scope.md):
unpushed commits plus staged, unstaged, and relevant untracked task edits.
Fetch first, verify the actual tracked upstream, and record its merge base
with HEAD. Do not assume `origin/mainline`, guess `HEAD~1`, or substitute an
older goal base. Ask for an explicit base if the upstream boundary cannot be
established; never default to the whole repository.

Create a run directory at `<owning repository or package>/.ai/go/<run-id>/`.
Keep **every workflow-generated artifact under that target's `.ai/`**: scope
snapshots, patches, helper scripts, build/test logs, coverage, CRAP/DRY results,
Lean projects and checker evidence, mutation results and recovered backups,
and the final summary. Use `.ai/reviews/` for all review reports, logs, and finding
dispositions in steps 5 and 6, including the record of changes made after review.
Pass absolute output paths and this requirement to every delegated skill,
agent, and tool, overriding their default temporary or external evidence
locations. If a tool requires a fixed output path, relocate completed artifacts
into the run directory after the tool and any required recovery finish.

Verify that transient run artifacts are ignored by Git so writing evidence
does not dirty a mutation checkpoint. If needed, exclude only this run directory
locally through the path returned by `git rev-parse --git-path info/exclude`;
preserve existing entries because that file is shared across worktrees. Honor
repository policy for versioned reports.

Record the base revision, original goal, target paths, staged/unstaged changes,
relevant untracked files, and renamed/deleted paths in the run directory.
**Keep the comparison base fixed across commits** and update the in-scope
line/function inventory as fixes change the code. A clean working tree after
a checkpoint does not mean the implementation disappeared.

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
**CRAP <= 10**, with its documented single-question conditional exception.
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
unit coverage, and CRAP, then use the named committer to checkpoint the changes
before review. Simplify itself does not commit. Record the checkpoint SHA for
each owning package while retaining its original comparison base.

## 5. Run reviewers in parallel

Prepare all applicable reviews below before launching them. Give each reviewer
the same complete goal inventory, fixed comparison bases, and recorded checkpoint
SHAs. All task source and tests must be committed. An uncommitted-only review
after a checkpoint does not cover this scope.

Launch the review passes concurrently through separate jobs or agents, starting
all of them before waiting for results. Request review only: reviewers must not
edit source or tests, commit, or start their own fix loops. Keep the reviewed
files unchanged until every reviewer finishes. If the snapshot changes meanwhile,
invalidate affected results and repeat those reviews on a validated checkpoint.

Give each reviewer its own absolute output paths under the target's `.ai/reviews/`.
Preserve earlier reports there before rerunning. The coordinator alone writes
the combined `.ai/reviews/OverallReview.md` in step 6. Track each review separately;
unavailable tooling, failed execution, or unusable output blocks that review.

### 5a. Codex /review

Run Codex's built-in `/review`. For automation, use `codex review` from the task
worktree with custom instructions specifying the shared scope and checkpoint.
Save the complete output to `.ai/reviews/CodexReview.md`.

### 5b. Overall code review

Invoke `overall-code-review` in review-only mode and follow its `edrevn` workflow.
Save the complete raw review to `.ai/reviews/review.md`. For this invocation,
return the findings and defer fixes and the combined disposition report to step 6.

### 5c. Local reviews

Before launching the parallel stage, read
`~/.agents/skills/go/references/local-reviews.md` if it exists, resolving the path
from the user's home directory. Run its applicable review passes alongside 5a and
5b with the same scope, checkpoint, review-only boundary, and evidence rules.

## 6. Resolve findings and record updates

Wait for all review passes to finish, then consolidate their findings. Deduplicate
overlaps while retaining every source, severity, and reviewer outcome. Assess all
action items, especially blockers, majors, and architectural feedback. The
coordinator applies warranted fixes; reviewers never edit concurrently.

Write `.ai/reviews/OverallReview.md` using the `overall-code-review` disposition
format. For each finding, record what was updated, the affected files and code
locations, the validation result, and the resulting checkpoint when fixed. For
anything left unchanged, record why. Include each review's scope, checkpoint,
report path, and status, including failures or reviews with no findings.
Preserve earlier rounds so the report records both the feedback and subsequent
changes. A confirmed, in-scope, unresolved blocker or major prevents completion;
a documented false positive is not an unresolved defect.

After fixes, rerun build, unit coverage, and CRAP, then use the named committer
to checkpoint the changes. Refresh affected reviews against that checkpoint
without changing the comparison bases; follow any stricter resubmission rules
from local integrations. Repeat assessment for new findings. Evidence invalidated
by later edits cannot count as a passing review.

## 7. Check DRY, verify Lean properties, and checkpoint

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

After DRY or proof-driven fixes, rerun build, unit coverage, CRAP, and affected
DRY/proof checks. Revisit simplify when changes materially alter its conclusions,
and follow step 6's checkpoint and review-refresh rules. Record these updates
and their validation in `.ai/reviews/OverallReview.md`. Do not reuse evidence
invalidated by changes to source or tests.

Once these gates pass, use the committer to commit all remaining in-scope
source, tests, and versioned task artifacts, including review reports when
repository policy permits them. Record this checkpoint. Required checks that
remain failed, unproved, or unsupported prevent an all-passed result.

## 8. Mutation-test committed code

Before **every mutation execution**, require a valid recorded checkpoint and
an empty `git status --porcelain=v1 --untracked-files=all`. Ignored build caches
and ignored `.ai/` evidence do not need commits. Unrelated dirty work blocks
mutation; do not include it in a commit without authorization.

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

## 9. Verify the final state and report

Verify that normal source is restored and every gate's evidence covers the final
source and tests. Refresh affected checks when code, tests, manifests, or source
hashes changed; do not invent a pass from a clean Git status. Run final `bbr`
when changes since the last passing build require it.

Use the committer for any remaining validated task changes. Finish with a clean
task working tree and record the final checkpoint hashes. If unrelated work or
an unavailable check prevents completion, report the exact limitation.

Write a concise summary in `.ai/go/<run-id>/` and report its path,
all review report paths, files updated and why, commits, build result,
changed-code coverage numerator and denominator, maximum in-scope CRAP, DRY
dispositions, mutation results, and Lean proof status/assumptions. List unresolved
issues first. Claim completion only when all required gates pass or have a
justified applicability exclusion; an explicit user waiver must be reported as a
waiver, not a passed check.
