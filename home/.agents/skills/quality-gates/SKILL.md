---
name: quality-gates
description: Apply tests, CRAP, mutation, and DRY gates to Python, Go, Java, TypeScript, Rust, and Clojure with Crapper, Mutator, and Dryer, with optional Gherkin/APS checks. Use when hardening code, evaluating test strength, creating or validating Gherkin features, or explicitly running code-quality checks.
---

# Quality Gates

Apply the quality model through the project's existing tests and the shared
`crapper`, `mutator`, and `dryer` tools, including Python projects.

## Operating rules

- Inspect the repository's actual build, test, coverage, feature, and mutation configuration before choosing commands.
- Capture [the local-change scope](references/change-scope.md) and establish a passing baseline before quality analysis. Include unpushed commits and pending task edits; exclude unchanged code already upstream.
- Use the public tool manager at `~/.agents/tools/quality-gates/bin/quality-tool`. Do not rely on an unrelated executable found on `PATH`.
- Run coverage, CRAP, DRY, language mutation, Gherkin mutation, and structure checks sequentially, never concurrently.
- Cap tools at four workers when they support worker limits.
- Follow [mutation artifact restoration](references/change-scope.md#mutation-artifacts-and-restoration) for source, worker state, and EDN snapshots.
- Preserve Gherkin mutation manifests. Never edit or discard them by hand.
- Treat missing required tools or test infrastructure, a red baseline, and mutation survivors/errors as blockers.
- Keep retained reports and evidence in the selected feature using [the shared artifact rule](../../rules/ai-artifacts.md). Preserve native build, cache, and recovery paths as described in [tool output paths](../../rules/ai-artifact-tools.md). Keep downloaded tools outside the repository.

## Workflow

1. Read [references/quality-gates.md](references/quality-gates.md), select the test workflow, and identify which gates apply.
2. Detect the owning language and use the matching tool skills:
   - Python, Go, Java, TypeScript, Rust, Clojure: `crapper`, `mutator`, and `dryer`.
   - JavaScript: `crapper` and `mutator`; Dryer currently does not parse JavaScript. Use a verified project DRY tool or report that gate blocked when required.
   - Other languages: verify project-native equivalents; do not claim universal language support.
   - APS tools, when applicable to the selected workflow: `gherkin-parser`, `gherkin-ir-dry-checker`, and `gherkin-mutator`.
3. Read [references/tools.md](references/tools.md) for shared installation and path rules.
4. When Gherkin is requested or feature files exist, read [references/gherkin.md](references/gherkin.md) for execution and package ownership. Inspect the existing runner before selecting APS tools.
5. Run the project's focused unit tests and applicable integration/acceptance tests through their existing runners to establish a passing baseline.
6. Generate fresh coverage before CRAP or language mutation.
7. Run mutation scan/count mode on each changed source file. Split only files that genuinely mix responsibilities.
8. Run `mutator` one selected file at a time with explicit `--lines` from the captured change scope and `--mutate-all` to rerun cached kills. Kill every survivor and resolve every tool error.
9. Apply [the shared Gherkin mutation applicability rules](references/quality-gates.md#test-workflow). Run required APS mutation with the persistent project adapter; report inapplicable gates as skipped with a reason.
10. Run CRAP on selected files and apply the shared per-function limit and single-question exception from [the gate policy](references/quality-gates.md). Preserve stricter tool failures in the report.
11. Run `dryer` and review only candidates involving affected functions. Similarity alone does not prove harmful duplication.
12. Re-run focused unit tests, applicable integration/acceptance tests, and project release checks.

Report every gate as `passed`, `failed`, `blocked`, or `skipped`, with the command and evidence. Do not describe an unrun gate as passed.
