---
name: quality-gates
description: Apply tests, CRAP, mutation, and DRY gates to Python, Go, Java, TypeScript, Rust, and Clojure with Crapper, Mutator, and Dryer, with optional Gherkin/APS checks. Use when hardening code, evaluating test strength, creating or validating Gherkin features, or explicitly running code-quality checks.
---

# Quality Gates

Apply the quality model through the project's existing tests and the shared
`crapper`, `mutator`, and `dryer` tools, including Python projects.

## Operating rules

- Inspect the repository's actual build, test, coverage, feature, and mutation configuration before choosing commands.
- Capture [the local-change scope](references/change-scope.md) and establish a passing baseline before quality analysis. Reuse a caller's recorded bases and task inventory across checkpoints. Include unpushed commits and pending task edits; exclude unchanged code already upstream.
- Follow [selection and evidence reuse](references/quality-gates.md#selection). A caller may supply the selected checks and their reasons; honor project requirements without expanding that selection into the full suite.
- Use the public tool manager at `~/.agents/tools/quality-gates/bin/quality-tool`. Do not rely on an unrelated executable found on `PATH`.
- Run selected coverage, CRAP, DRY, Lean, mutation, and structure checks sequentially, never concurrently.
- Cap tools at four workers when they support worker limits.
- Follow [mutation artifact restoration](references/change-scope.md#mutation-artifacts-and-restoration) for source, worker state, and EDN snapshots.
- Preserve Gherkin mutation manifests. Never edit or discard them by hand.
- Treat missing required tools or test infrastructure, a red baseline, and mutation survivors/errors as blockers.
- Keep retained reports and evidence in the selected feature using [the shared artifact rule](../../rules/ai-artifacts.md). Preserve native build, cache, and recovery paths as described in [tool output paths](../../rules/ai-artifact-tools.md). Keep downloaded tools outside the repository.

## Workflow

1. Read [references/quality-gates.md](references/quality-gates.md), select the test workflow, and record which gates apply and why. Reuse verified matching evidence; execute only selected checks that need current evidence.
2. Detect the owning language and use the matching skills for selected tools:
   - Python, Go, Java, TypeScript, Rust, Clojure: `crapper`, `mutator`, and `dryer`.
   - JavaScript: `crapper` and `mutator`; Dryer currently does not parse JavaScript. Use a verified project DRY tool or report that gate blocked when required.
   - Other languages: verify project-native equivalents; do not claim universal language support.
   - APS tools, when applicable to the selected workflow: `gherkin-parser`, `gherkin-ir-dry-checker`, and `gherkin-mutator`.
3. Read [references/tools.md](references/tools.md) for shared installation and path rules.
4. When Gherkin is requested or feature files exist, read [references/gherkin.md](references/gherkin.md) for execution and package ownership. Inspect the existing runner before selecting APS tools.
5. Establish a passing baseline for selected validation. Reuse matching test/build evidence or run the project's focused tests and applicable integration/acceptance tests through their existing runners.
6. Generate fresh coverage when selected or needed by CRAP or language mutation. For selected finalization coverage, use [the shared measurement procedure](references/finalization.md#changed-code-unit-coverage).
7. When selected, run CRAP on selected files and apply the shared per-function limit and conditional exception. Preserve stricter tool failures in the report.
8. When selected, run `dryer` and review candidates involving affected functions. Similarity alone does not prove harmful duplication.
9. When selected, follow [the Lean procedure](references/finalization.md#lean-properties) and retain checked properties, source correspondence, and assumptions.
10. For selected language mutation, scan each selected changed source file. Split only files that genuinely mix responsibilities. During `code-finalizer`, enforce [clean checkpoints](references/finalization.md#mutation-checkpoints) before every invocation; use the caller's committer authority after build checks, or report a required new checkpoint blocked.
11. When language mutation is selected, run `mutator` one selected file at a time with explicit `--lines` from the captured change scope and `--mutate-all` to rerun cached kills. Kill every survivor and resolve every tool error.
12. Apply [the shared Gherkin mutation applicability rules](references/quality-gates.md#test-workflow). Run selected APS mutation with the persistent project adapter; report inapplicable gates as skipped with a reason.
13. Re-run focused tests, applicable integration/acceptance tests, and release checks when changes invalidate their evidence. Refresh affected earlier gates after fixes; do not repeat unaffected passing checks.

Report every gate as `passed`, `failed`, `blocked`, or `skipped`, with the command and evidence. Do not describe an unrun gate as passed.
