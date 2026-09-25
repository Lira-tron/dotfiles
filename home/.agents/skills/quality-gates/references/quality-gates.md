# Quality gates

Use only the gates relevant to the requested change.

Quality gates MUST use
[the scope of local changes](change-scope.md): unpushed commits plus staged,
unstaged, and relevant untracked task edits, captured before tool runs or
checkpoint commits. This shared policy also applies when a language tool skill
is invoked directly.

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

These are the applicable requirements; use the final hardening sequence below
for execution order.

1. Agreed, deterministic acceptance criteria when externally visible behavior changes, using the selected test workflow.
2. Passing unit tests and applicable integration/acceptance tests.
3. Fresh coverage before CRAP or mutation.
4. CRAP `<= 8` on affected functions, subject to the documented conditional exception.
5. DRY findings reviewed and harmful duplication reduced.
6. Changed/new source scanned for mutation sites and mixed responsibilities.
7. Language mutation restricted to changed source lines in that scope, with zero survivors and zero execution errors.
8. Differential Gherkin mutation when applicable under the test workflow rules above.
9. Separate property-test command when the project has property tests.
10. Independent UI, architecture-sensitive, and release verification when applicable.

The final hardening sequence, omitting inapplicable gates, is:

```text
language mutation -> Gherkin mutation -> CRAP -> DRY
```

Fix a failing gate before moving to the next one.

## Strict and advisory checks

- CRAP normally requires `<= 8` for each affected function; exactly 8 passes.
  A single `cond`, `case`, or equivalent `switch` answering one question may
  exceed 8. Record the function, score, and reason as an exception, not a
  numeric pass. Nested or mixed-responsibility functions over 8 must be
  simplified or split. An extracted function must own its inputs; do not
  introduce boolean-parameter helpers merely to lower the score. Honor
  stricter project limits and report stricter tool failures separately.
- Mutation is a result gate: no surviving mutants or mutation execution errors.
- Applicable Gherkin mutation uses the same result gate; missing prerequisites are blockers.
- Coverage has no universal numeric threshold here. It must be fresh and sufficient to support CRAP and mutation analysis.
- DRY results are candidates, not automatic defects. Remove duplication only when the duplicated knowledge or responsibility should have one owner.
- Go uses `dry4go`; Java uses `dry4java`. Record each in-scope candidate's
  disposition. Unresolved harmful duplication blocks the DRY gate; incidental
  structural similarity does not. Shared agent rules should likewise have
  one canonical source, referenced by client instructions and workflows.
- Mutation-site count is a design signal, not a file-size quota. Split a module when it has more than one job, not merely to reduce the count.

## Default policy

Use four workers and, when applicable, differential Gherkin mutation at `--level hard` unless the user or project explicitly selects different behavior.
