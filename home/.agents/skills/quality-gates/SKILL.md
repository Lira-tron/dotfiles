---
name: quality-gates
description: Apply test, CRAP, language mutation, and DRY quality gates to Go or Java changes, with optional Gherkin/APS checks. Use when hardening code, evaluating test strength, creating or validating Gherkin features, or explicitly running code-quality checks.
---

# Quality Gates

Apply the quality model directly to Go and Java projects.

## Operating rules

- Inspect the repository's actual build, test, coverage, feature, and mutation configuration before choosing commands.
- Capture [the local-change scope](references/change-scope.md) and establish a passing baseline before quality analysis. Include unpushed commits and pending task edits; exclude unchanged code already upstream.
- Use the public tool manager at `~/.agents/tools/quality-gates/bin/quality-tool`. Do not rely on an unrelated executable found on `PATH`.
- Run coverage, CRAP, DRY, language mutation, Gherkin mutation, and structure checks sequentially, never concurrently.
- Cap tools at four workers when they support worker limits.
- Preserve language and Gherkin mutation manifests. Never edit or discard them by hand.
- Treat missing required tools or test infrastructure, a red baseline, and mutation survivors/errors as blockers.
- Keep generated output in ignored build directories unless the project already tracks that artifact. Keep downloaded tools outside the repository.

## Workflow

1. Read [references/quality-gates.md](references/quality-gates.md), select the test workflow, and identify which gates apply.
2. Detect the owning language and use the matching tool skills:
   - Go: `crap4go`, `mutate4go`, and `dry4go`.
   - Java: `crap4java`, `mutate4java`, and `dry4java`.
   - APS tools, when applicable to the selected workflow: `gherkin-parser`, `gherkin-ir-dry-checker`, and `gherkin-mutator`.
3. Read [references/tools.md](references/tools.md) for shared installation and path rules.
4. When Gherkin is requested or feature files exist, read [references/gherkin.md](references/gherkin.md) for execution and package ownership. Inspect the existing runner before selecting APS tools.
5. Run the project's focused unit tests and applicable integration/acceptance tests through their existing runners to establish a passing baseline.
6. Generate fresh coverage before CRAP or language mutation.
7. Run mutation scan/count mode on each changed source file. Split only files that genuinely mix responsibilities.
8. Run language mutation one selected file at a time with explicit `--lines` from the captured change scope. Kill every survivor and resolve every tool error.
9. Apply [the shared Gherkin mutation applicability rules](references/quality-gates.md#test-workflow). Run required APS mutation with the persistent project adapter; report inapplicable gates as skipped with a reason.
10. Run CRAP on selected files and apply the shared per-function limit and single-question exception from [the gate policy](references/quality-gates.md). Preserve stricter tool failures in the report.
11. Run `dry4go` or `dry4java` and review only candidates involving affected functions. Similarity alone does not prove harmful duplication.
12. Re-run focused unit tests, applicable integration/acceptance tests, and project release checks.

Report every gate as `passed`, `failed`, `blocked`, or `skipped`, with the command and evidence. Do not describe an unrun gate as passed.
