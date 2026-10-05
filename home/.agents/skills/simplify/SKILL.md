---
name: simplify
description: Review recently changed code with concurrent subagents for reuse, simplification, efficiency, and abstraction level, then apply behavior-preserving improvements. Use when the user requests a simplify pass or asks to clean up a recent code change.
---

# Simplify

Improve the changed code without changing its intended behavior. Use four
concurrent reviewers, then consolidate their findings and apply the worthwhile
fixes yourself.

Accept optional paths, a comparison base, or a focus in the user's request, for
example `$simplify src/cache/ focus on unnecessary work`. Honor review-only
requests by returning findings without editing.

## 1. Establish the scope

- Follow the repository instructions and the user's specified scope first.
- In a working tree with unrelated changes, use the current task's files when
  that boundary is known; ask if ownership or scope is ambiguous.
- Inspect Git status, staged and unstaged changes, and relevant non-ignored
  untracked source files. Include newly added files; `git diff` alone omits them.
  If HEAD exists, `git diff HEAD` shows the combined tracked changes.
- If the user supplies a base, inspect the changes from that base and state the
  comparison. Do not silently substitute another branch.
- With no pending changes, use files explicitly identified by the user or
  changed during this conversation. If neither identifies a target, ask for
  the files or comparison base. Do not invent a target from the latest commit
  or expand to the entire repository.
- Outside Git, review the explicit target files and use their current contents
  as the common input.
- Read the changed files and enough surrounding code to understand the contracts
  and existing conventions. Note the appropriate focused validation command.
- When scoped files include `.smithy` or `smithy-build.json`, read
  `~/.agents/skills/smithy/SKILL.md` and its referenced guide. Give every reviewer
  the resolved guide path and require them to read it. If it is unavailable,
  report Smithy-rule review as unverified and continue the supported cleanup.
  Do not load Smithy guidance when those files are outside the review scope.
- Prepare one common review input: repository root, target paths, full diff
  (including relevant new-file contents), user focus, applicable constraints,
  comparison base, and the paths of any language guides loaded for this scope.
  A shared temporary file is fine for a large diff. If the scope is too large to
  review fully, narrow it with the user instead of silently truncating it.

## 2. Run four reviews concurrently

Use Codex's native subagent tools; discover them first if they are deferred.
Keep orchestration in the session that has these tools; do not delegate the
entire workflow to a child that cannot spawn reviewers.
Launch all four reviewers before waiting for any result. Independent spawn
calls that return immediately are sufficient; their work must overlap.
Use the built-in `default` agent and inherit the current model unless the user
requests otherwise. No custom agent definitions or external CLIs are required.

Give each reviewer the common input and exactly one lens from below. Tell each:

> Review only; do not edit files or delegate to other agents. Read the full
> supplied diff and inspect relevant source and callers yourself. Report only
> concrete improvements in scope. For each finding, return the file and line,
> the observed issue, its practical cost, and a specific behavior-preserving
> fix. Cite any existing helper you propose reusing and check that its semantics
> match. Do not manufacture findings to fill a quota; an empty result is valid.
> Read any supplied language guides and report violations in the scoped changes.
> If a correction would change public or generated APIs, report it as requiring
> a separate contract change instead of proposing it as behavior-preserving cleanup.
> Include the revision/base and guide files you actually read in your result.

The reviewers analyze the same stable version of the code. Do not modify the
reviewed files until all four finish. If the user or another process changes
them meanwhile, reconcile those changes before applying affected findings.

### Reviewer 1: Reuse

Search the repository for existing functions, utilities, types, and conventions
that already solve the new code's problem. Identify duplicated behavior and
inline reimplementations of existing helpers. Prefer direct reuse where
semantics and dependency boundaries match. Do not introduce a shared abstraction
for a single use or couple unrelated modules just because their code looks alike.

### Reviewer 2: Simplification

Look for redundant state, unnecessary indirection, excessive parameters,
copy-paste variations, weakly structured data where the codebase has a suitable
type. Prefer clearer control flow and fewer concepts. Remove only comments
or structural wrappers made unnecessary by the scoped cleanup; avoid cosmetic
churn, nested ternaries, and compressed code that is harder to read.

### Reviewer 3: Efficiency

Look for repeated computation or I/O, redundant allocations, repeated linear
lookups, unnecessary hot-path work, overly broad reads, retained resources, and
missed concurrency between genuinely independent operations. Explain the
concrete work saved. Verify ordering, failure, lifecycle, and shared-state
semantics before suggesting concurrency, caching, batching, or removal of a
guard. Avoid speculative optimization.

### Reviewer 4: Abstraction level

Inspect changed functions and their callers for mixed levels of detail, thin
forwarding layers, exposed implementation details, and responsibilities split
across places that must change together. Prefer boundaries that hide meaningful
complexity. Suggest a small local restructuring only when it makes the code
easier to understand or change; do not create helpers that merely rename an
expression or turn the cleanup into an architectural rewrite.

## 3. Consolidate and simplify

- Wait for all four reviews, collect their results, and close their completed
  agent threads when supported. If a review fails, retry that review when the
  error is recoverable. If native concurrent review remains unavailable or
  incomplete, report the limitation; do not present a serial or partial run as
  a completed concurrent pass.
- Deduplicate overlapping findings and inspect each candidate against the
  current code. Skip false positives, subjective style changes, broad rewrites,
  and suggestions whose behavior preservation cannot be established.
  Keep confirmed language-rule violations requiring contract changes in the
  report as unapplied findings; do not silently discard or fix them as cleanup.
- Apply the smallest useful fixes yourself. The coordinator is the sole writer;
  reviewers must never patch overlapping files.
- Preserve observable behavior, public interfaces, error semantics, ordering,
  side effects, and relevant performance characteristics. Keep unrelated user
  changes intact. This is a cleanup pass, not a general bug or security audit.
- Do not commit, push, add dependencies, or change project configuration merely
  to complete this pass.

## 4. Verify and report

Inspect the final diff for unintended changes and run the focused tests, build,
or checks appropriate to the affected code and repository instructions.
Compare with the initial state when needed to distinguish existing failures.
If a regression comes from your cleanup, fix it or undo only your own change.
Do not weaken tests to accommodate a refactor.

Summarize the scope, improvements, and validation result. State any failed
review or unavailable check. If no worthwhile changes remain, say so. Do not
claim equivalence or performance gains that were not established.
For Smithy scopes, include the reviewed revision/base, guide files actually read,
and any unapplied model-rule findings.

For the implementation rationale and source comparison, maintainers can read
[the research notes](references/research.md); normal runs do not need them.
