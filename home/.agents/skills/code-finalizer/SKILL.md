---
name: code-finalizer
description: Finalize a completed task before CR submission when explicitly requested or selected by a requested workflow such as CR submission. Select relevant validation and reviews, resolve findings, and record readiness. Ordinary development, commits, and approval do not invoke this skill.
---

# Code finalizer

Run once the requested development is complete. An explicitly requested
workflow may select this skill at its final stage; CR submission can call it
automatically when the change warrants finalization. A very small, low-risk
submission may instead use its caller's focused validation path. An explicit
request for this skill still runs its selection and readiness checks.

`go` does not call this skill automatically. Select checks for the accumulated
task, not for every edit or commit. A later correction resumes the affected
checks rather than starting the entire suite again.

Invocation authorizes scoped corrections and checkpoint commits through the
named committer in [commit](../commit/SKILL.md). Honor explicit review-only and
no-commit restrictions. Keep deployment, CR creation, and publication in their
separately authorized workflows.

## 1. Establish scope and evidence

Reuse the checkout selected through [worktree](../worktree/SKILL.md). Capture
[the shared local-change scope](../quality-gates/references/change-scope.md),
including unpushed and pending task changes, after fetching the actual upstream.
Keep each package's comparison base fixed across checkpoints.

Read the original requirements, acceptance criteria, and project instructions.
Resolve [the feature's artifact directory](../../rules/ai-artifacts.md). Keep
this run under `<AI_ARTIFACT_ROOT>/finalization/<run-id>/` and review outputs
under `<AI_ARTIFACT_ROOT>/reviews/`. Pass absolute source and artifact paths to
every producer. Preserve previous results and unrelated work.

Record the package set, bases, starting revisions, full task diff, and
source/test/configuration identity. Confirm the requested behavior is complete;
missing requirements are findings, not permission to invent more features.

## 2. Select the final checks

Use [quality-gates' selection policy](../quality-gates/references/quality-gates.md#selection)
to choose validation. Read its
[finalization details](../quality-gates/references/finalization.md) only for
selected changed-code coverage, Lean, or mutation checks.

Read `~/.agents/skills/code-finalizer/references/local-reviews.md` if present.
Resolve this path from the user's home; it describes available local reviews.
Tool availability or repository language alone does not select a check.

Record each selected check or review, its concrete purpose or mandatory rule,
and the evidence it must produce. Record omissions as `skipped` with a reason.
An omitted optional check is not a pass; missing tooling for a required or
selected check is `blocked`. Honor an explicit user waiver as a waiver.

Choose reviews that answer distinct concerns:

| Review | When it adds value |
| --- | --- |
| [code-review](../code-review/SKILL.md) | Substantive changes needing an independent standards or requirements assessment. |
| [overall-code-review](../overall-code-review/SKILL.md) | A requested external review, a project requirement, or a concrete concern requiring another assessment. |
| [adversarial-reviewer](../../agents/adversarial-reviewer.md) | Authorization, concurrency, recovery, state transitions, or other invariants that warrant counterexample-driven review. |
| Local reviews | The local integration's specific selection criteria, a user request, or a project requirement. |

Small mechanical changes may need only focused validation. Treat executable
agent instructions by their behavioral impact, not their Markdown extension.
Do not select every reviewer by default.

Reuse earlier evidence only after verifying it covers the selected task scope
and current source, tests, requirements, configuration, and relevant runtime or
toolchain inputs. A clean Git status or a previous summary alone is insufficient.
Reused evidence keeps its original provenance; do not report a new execution.

## 3. Validate and checkpoint

Run [simplify](../simplify/SKILL.md) only when a concrete cleanup concern warrants
it and matching evidence is unavailable. Apply useful scoped improvements.

Delegate the selected validation to [quality-gates](../quality-gates/SKILL.md),
supplying the fixed bases, complete task inventory, selection, evidence paths,
and current commit authority. That skill owns validation order and thresholds.
Keep checks sequential and complete mutation restoration before any real edits.

Build before checkpointing code through the named committer. Reuse an existing
validated checkpoint when possible. For selected mutation, follow the shared
finalization requirement for a clean, committed checkpoint before every
invocation, including scans. If fixes require an unauthorized commit, report
that check blocked; preserve unrelated dirty work.

Commit validated in-scope source and tests before the selected reviews. Record
the exact checkpoint for each package; the comparison bases remain unchanged.
A review-only or no-commit run may use an existing matching checkpoint.

## 4. Run selected reviews in parallel

Prepare only selected review jobs that need fresh evidence; retain verified
matching results as reused. Start all prepared jobs before waiting.
Supply the same full task inventory, fixed bases, checkpoint revisions, and
requirements. Reviewers inspect source themselves and return findings only.
Keep source and tests unchanged until every reviewer finishes; the coordinator
alone applies corrections.

For `code-review`, keep orchestration where its two native Standards and Spec
subagents can be launched. Run those axes concurrently with each other and the
other selected jobs. Preserve their separate verdicts in `StandardsSpecReview.md`.
For `overall-code-review`, use its `edrevn` procedure in review-only mode and
retain the raw `review.md`; defer dispositions to the coordinator.

For adversarial review, use a fresh context (`fork_context: false` in Codex).
Supply the original requirements, checkout paths, bases, inventory, and
checkpoints. Keep other reviewers' reports and the implementer's correctness
rationale out of its context. Save its returned output as `AdversarialReview.md`.
Local reviews follow their own report paths and submission contracts.

Give each job separate absolute outputs under the feature's `reviews/`.
Track unavailable, failed, incomplete, and successful jobs separately. If the
source changes during a review, invalidate the affected result.

## 5. Resolve findings and refresh affected evidence

After all selected reviews finish, consolidate their findings in
`<AI_ARTIFACT_ROOT>/reviews/OverallReview.md` using the
[disposition format](../overall-code-review/SKILL.md#4-write-the-disposition-report).
Preserve severity, source, scope, and each review's outcome. Record every finding
as fixed with validation, or unchanged with an evidence-backed reason.

Apply warranted corrections within the task. Rebuild and checkpoint changed
code through the committer, then rerun only checks and reviews invalidated by
the correction. Refresh changed-line mappings without changing the fixed bases.
Source, test, requirement, and configuration changes can invalidate different
evidence; assess their actual dependencies. Honor stricter resubmission rules
for selected external reviews. A failure or stale result cannot become a skip
merely to finish.

## 6. Record readiness

Write `<AI_ARTIFACT_ROOT>/finalization/<run-id>/report.md` with:

- Original requirements, task scope, package/base/checkpoint mapping, source
  tree IDs, and source/test/configuration hashes needed to verify evidence reuse.
- Selected and skipped checks with reasons, results, commands, evidence paths,
  reused results, and relevant environment or toolchain identity.
- Findings, corrections, validation, and any explicit waivers or blockers.
- Readiness for the intended CR diff, including a clean task working tree,
  restored mutation state, and final checkpoint mapping.

Declare ready only when the requirements are satisfied, required and selected
checks have current passing evidence or an explicit waiver, and no confirmed
in-scope blocker or major remains. Report a waiver explicitly in the readiness
verdict. Omit inapplicable tool metrics rather than inventing passing values.

Return the report path and concise result. Submission verifies this evidence
against the intended CR package set and diff. Message-only CR footer amendments
may change commit IDs without invalidating unchanged source and diff evidence.
