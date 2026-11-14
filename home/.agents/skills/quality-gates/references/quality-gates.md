# Quality gates

Use only the gates relevant to the requested change.

Quality gates MUST use
[the scope of local changes](change-scope.md): unpushed commits plus staged,
unstaged, and relevant untracked task edits, captured before tool runs or
checkpoint commits. This shared policy also applies when a language tool skill
is invoked directly.

## Selection

Honor the user's requested checks and mandatory project rules first. Otherwise,
select checks that answer a concrete concern in the task. Language support or
tool availability alone does not require a full hardening run.

| Check | Selection reason |
| --- | --- |
| Tests and build | Verify affected behavior and satisfy the owning project's checks; use its existing integration/acceptance runner when the changed contract requires it. |
| Coverage and CRAP | Assess coverage or complexity of affected executable behavior, or satisfy a project requirement. |
| DRY | Investigate duplicated knowledge or responsibilities introduced or changed by the task. |
| Language mutation | Check assertion strength for changed decisions, failure paths, or other behavior where a passing test may miss defects. |
| Lean | Check an explicit behavioral property whose model can be meaningfully related to the implementation. |
| Gherkin/APS | Follow the applicability rules below for the selected test workflow. |

Use focused checks during development. At finalization, assess the complete
accumulated task and record selected checks and concrete reasons. A caller's
selection does not waive mandatory project rules. Record omitted checks as
`skipped` with reasons, never as passed. A selected check with missing tools,
an execution failure, or inconclusive evidence remains blocked or failed.

Reuse a prior result only after verifying its scope, source and test identity,
requirements, configuration, and relevant environment/toolchain still match.
Retain the original command, evidence, and provenance. After a correction,
refresh only checks whose inputs or conclusions were affected. A test change can
invalidate mutation evidence even when production source is unchanged.

## Test workflow

- Default to complete tests in the project's existing unit and integration-test
  frameworks. The agent writes the setup, calls, and assertions, and the existing
  runner executes those tests. This path needs no `.feature` files or generator.
- Use Gherkin when the user requests it or the project already uses it. Preserve
  the existing Gherkin framework; a `.feature` file alone does not select APS.
  A request to draft or parse features does not require new execution infrastructure.
- Use the APS generator, runtime, and mutation adapter only when the project
  already uses APS or the user requests that workflow. See
  [Gherkin execution and package ownership](gherkin.md).
- Gherkin mutation applies only to the selected APS workflow's feature files
  within the captured change scope. If APS is not selected or no APS features
  are in scope, report this gate as `skipped` with the reason.
  For an applicable APS run, missing generated entrypoints or a required adapter,
  or a failing or unverified baseline, makes the gate `blocked`; do not silently
  skip it or switch workflows.

## Test package ownership

Before writing tests, identify the owning package, framework, execution command,
and required environment from the existing test and build configuration.
Keep unit tests in their established locations. For scenarios that call a
deployed service, use the existing integration-test package and its runner.
For local component scenarios, use the package and suite that own that boundary.
In Brazil, keep authored tests inside `workspace/src/<OwningPackage>/`, following
its existing layout. Verify the suite's execution command separately from its
packaging build.

## Required checks

For Python, Go, Java, TypeScript, Rust, and Clojure, use the shared
[`crapper`](../../crapper/SKILL.md), [`mutator`](../../mutator/SKILL.md), and
[`dryer`](../../dryer/SKILL.md) skills. Crapper and Mutator also support
JavaScript; Dryer currently does not. Verify equivalents for other languages
and report missing required support as blocked.

For selected checks, apply these requirements and the execution order below.
Selection does not lower a selected check's result threshold.

1. Agreed, deterministic acceptance criteria when externally visible behavior changes, using the selected test workflow.
2. Passing unit tests and applicable integration/acceptance tests.
3. Fresh coverage before CRAP or mutation.
4. CRAP `<= 10` on affected functions, subject to the documented conditional exception.
5. DRY findings reviewed and harmful duplication reduced.
6. Changed/new source scanned for mutation sites and mixed responsibilities.
7. Language mutation restricted to changed source lines in that scope, with zero survivors and zero execution errors.
8. Differential Gherkin mutation when applicable under the test workflow rules above.
9. Separate property-test command when the project has property tests.
10. Independent UI, architecture-sensitive, and release verification when applicable.

The final hardening sequence, omitting inapplicable gates, is:

```text
tests/build -> coverage -> CRAP -> DRY -> Lean -> language mutation -> Gherkin mutation
```

Fix a failing gate before moving to the next one.
After fixes, refresh evidence for affected earlier checks. When invoked by
`code-finalizer`, apply the shared
[mutation checkpoint procedure](finalization.md#mutation-checkpoints) before
scans as well as executions.

## Strict and advisory checks

- CRAP normally requires `<= 10` for each affected function; exactly 10 passes.
  A single `cond`, `case`, or equivalent `switch` answering one question may
  exceed 10. Record the function, score, and reason as an exception, not a
  numeric pass. Nested or mixed-responsibility functions over 10 must be
  simplified or split. An extracted function must own its inputs; do not
  introduce boolean-parameter helpers merely to lower the score. Honor
  stricter project limits and report stricter tool failures separately.
- Mutation is a result gate: no surviving mutants or mutation execution errors.
- Applicable Gherkin mutation uses the same result gate; missing prerequisites are blockers.
- Coverage has no universal numeric threshold for development. When selected for finalization, use [the changed-code unit coverage requirement](finalization.md#changed-code-unit-coverage). Coverage must be fresh and sufficient to support selected CRAP and mutation analysis.
- DRY results are candidates, not automatic defects. Remove duplication only when the duplicated knowledge or responsibility should have one owner.
- Use `dryer` for its supported languages. Record each in-scope candidate's
  disposition. Unresolved harmful duplication blocks the DRY gate; incidental
  structural similarity does not. Shared agent rules should likewise have
  one canonical source, referenced by client instructions and workflows.
- Mutation-site count is a design signal, not a file-size quota. Split a module when it has more than one job, not merely to reduce the count.

## Default policy

Use four workers and, when applicable, differential Gherkin mutation at `--level hard` unless the user or project explicitly selects different behavior.
