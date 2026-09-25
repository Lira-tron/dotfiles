---
name: lean-verify
description: Verify code properties with Lean 4, across a repository or its uncommitted changes. Infer invariants, construct and check proofs, and report source-linked findings, assumptions, and verification gaps. Use when asked for Lean or formal verification.
---

# Lean verification

Use the repository as input: the user does not need to provide a specification
or Lean proofs. Infer candidate properties from requirements, code, tests, and
callers; implement the formalization and run Lean.

This skill validates and reports. Apply production fixes only when the user's
request also authorizes fixes. Preserve the current index and working tree.

## Select scope

- `all`: assess all current repository code, including nonignored untracked
  files. Account for every inventory entry; do not silently choose a few modules.
- `uncommitted` (default): staged changes, unstaged changes, and nonignored
  untracked files. Include deleted code and both sides of renames in impact
  analysis. Analyze the current working tree, not just the staged version.

Examples: `$lean-verify all`, `$lean-verify uncommitted`, or
`/lean-verify uncommitted` in a client with slash-command skill invocation.
Interpret the mode from the user's request; these are agent instructions, not
a standalone compiler for arbitrary source languages.

Read applicable repository instructions. Resolve the owning Git repository
explicitly when a workspace contains multiple repositories. Use the repository's
real build/test commands, including its package build system.

The helpers require Python 3.11+ and Git. Create a separate artifact directory
outside the repository:

```sh
skill="$HOME/.agents/skills/lean-verify"
run="$(mktemp -d "${TMPDIR:-/tmp}/lean-verify.XXXXXXXX")"
python3 "$skill/scripts/scope.py" --repo . --mode uncommitted --out "$run"
```

The helper writes `scope.json`, `staged.patch`, and `unstaged.patch`. It reads Git
without staging or changing files. `all` includes tracked and untracked entries;
binary files, symlinks, submodules, and deleted files remain visible for explicit
classification. It does not recurse into submodules or follow symlinks.

Only in `uncommitted` mode, if `scope.json.files` is empty, report `no_changes`
and stop. A clean repository still needs analysis in `all` mode. Classify
inventory entries as analyzed code, supporting material, excluded with a reason,
or unassessed. Inspect callers, dependencies, tests, and prior versions as needed;
record additional source paths and hashes in the report. A changed test,
configuration file, interface, or deletion may affect unchanged production code.

## Establish properties

Read [the report contract](references/report.md) before formalizing. Write the
candidate properties and their requirement evidence into `report.json`.
Distinguish a documented requirement from inferred intent; flag ambiguous or
contradictory requirements without silently choosing a convenient interpretation.

Prioritize relevant properties such as state transitions, bounds, preservation
of data, ownership, retry limits, and authorization decisions. For a large scope,
work by component and keep a complete inventory of outstanding work. A timeout
or context limit leaves that work `unassessed` or `unproved`, never passed.

Record source correspondence: which function or branch each Lean definition
represents, and which semantics are abstracted away. Preserve relevant integer
widths, overflow, errors, aliasing, event ordering, and side effects. In a
concurrency model, state atomicity and scheduling assumptions; liveness also
needs its fairness/environment assumptions. Avoid proofs made trivial by empty
reachable-state sets or assumptions equivalent to the conclusion.

## Construct and check

Use an existing compatible Lean project/toolchain when available. Otherwise,
create a small Lake library in the artifact directory with a pinned
`lean-toolchain`. Prefer the standard library when sufficient. If Lean is
missing, obtain a pinned release from the official Lean distribution in a user
cache, or report `blocked` if installation is unavailable. Keep downloaded
toolchains and generated proofs out of the source repository.

The checker tries Lake on `PATH`, then the cached toolchain at
`~/.cache/lean-verify/toolchains/lean-4.34.0-linux/bin/lake`.
Use `--lake` to select another executable. Never use a cached toolchain whose
version conflicts with an existing project's `lean-toolchain`.

Build faithful models and named theorems in `.lean` files. For native Lean code,
import and reason about the actual implementation. For other languages, report
proofs as model proofs; do not claim an automatic verified translation.

Run the checker for every claimed theorem, using its importable module name:

```sh
python3 "$skill/scripts/check.py" \
  --project "$run/proof" --module Verification \
  --theorem Verification.cancelledIsTerminal \
  --out "$run/checks/cancellation"
```

Repeat `--theorem` for multiple theorems in that module. The checker builds the
module, checks declaration types and transitive axiom dependencies, and writes
`evidence.json`, the generated audit, and logs. Only `propext`,
`Classical.choice`, and `Quot.sound` are allowed logical axioms. Other axioms,
`sorryAx`, and missing/non-theorem declarations are rejected. This also rejects
native-evaluation axioms; use a proof that the ordinary kernel can check.

A successful build alone is not a proof verdict. Inspect theorem statements,
definitions, and explicit hypotheses as well as checker evidence. The helper is
an ordinary Lean/axiom check, not an independent kernel checker or a sandbox
against hostile metaprograms.

Failure to finish a proof is `unproved`, not evidence of a code defect. Investigate
whether the issue is a false property, an inaccurate model, or proof difficulty.
For a suspected bug, produce a minimal counterexample and reproduce it against
the original implementation with its real test/runtime environment where
possible. Until that succeeds, classify it as a model counterexample or suspected
bug. Preserve the reproduction command, output, and suggested regression test.

Do not weaken a property or silently repair the model to make a proof pass.
Record a discovered specification correction explicitly and preserve the original
finding. Where delegation is available, an independent review of important
properties and model correspondence can catch shared assumptions.

## Deliver evidence

Write `report.json` and a concise `report.md` following the report contract.
Include confirmed bugs first, then model counterexamples, proved properties,
unproved properties, and scope/semantics gaps. Include concrete next actions
that another coding agent can execute.

Before finalizing, recompute hashes for all source and dependency files used.
Check that theorem evidence still matches its Lean sources and toolchain.
Mark changed inputs `stale` and rerun the affected work; do not reuse evidence
for a different source snapshot. Use fresh output directories when refreshing
scope or rerunning proofs; preserve previous snapshots and evidence.

Do not report a repository-wide correctness guarantee or invent a coverage
percentage from file counts. `all` is the requested scope, not a guarantee that
all behavior has been proved. Keep CRAP, tests, and mutation outcomes separate;
Lean adds evidence about the stated properties.

Official reference: https://lean-lang.org/doc/reference/latest/ValidatingProofs/
