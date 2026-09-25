# Gherkin acceptance specifications

Gherkin describes externally visible behavior in `Feature`, `Scenario`, `Given`, `When`, and `Then` form. It is a specification format, not the test runner.

Use [the shared test workflow policy](quality-gates.md#test-workflow) to select
direct tests, an existing Gherkin framework, or APS. Acceptance describes what
requirements a test verifies; unit or integration describes what it exercises.
Inspect the actual calls and dependencies to determine its level.

## Direct tests and APS

| Workflow | What the agent implements | What the existing test runner executes |
|---|---|---|
| Direct tests | Complete test cases with setup, calls, and assertions | Those test cases |
| APS | Reusable step handlers, an acceptance runtime, and a project-specific entrypoint generator | Generated test entrypoints that load scenario data and invoke the runtime and handlers |

The APS generator creates thin entrypoints; it does not implement API calls or
assertions. Handlers contain that project-specific code. If the agent has already
written complete tests for the existing runner, no generator is needed.
An existing framework that executes Gherkin directly keeps its own integration.
Features kept only as documentation do not automatically drive tests or APS mutation.

## Package ownership

Use [the shared test package ownership rules](quality-gates.md#test-package-ownership)
for both direct tests and Gherkin.

In a Brazil workspace with `MyService` and an existing `MyServiceTests` package,
an APS service-API scenario could live at
`src/MyServiceTests/features/upload.feature`, with its handlers in that package.
This is an example, not a required package name or a reason to create a new package.
Keep authored features and handlers in version-controlled package sources.
Follow [the generated-output policy](../SKILL.md#operating-rules) for JSON/tests.
Verify how the integration suite is launched: adding a feature does not wire it
into `brazil-build release`, and no deployment is implied by adding Gherkin.

## Writing features

The agent or developer authors selected Gherkin scenarios from the agreed
requirements and expected results.

```gherkin
Feature: Login

  Scenario: Login 1 - valid credentials
    Given a registered user
    When the user enters the correct password
    Then access is granted
```

- Specify user-visible behavior without prescribing implementation.
- Keep scenarios deterministic and concise.
- Use parameters and example tables only for values whose variation matters.
- Remove identical example columns that do not strengthen acceptance mutation.
- Move genuinely repeated setup into `Background`.
- Keep generated acceptance tests separate from unit tests.

## APS acceptance pipeline

Use this pipeline only when APS is selected under the shared policy.

1. Parse each feature into JSON IR with `gherkin-parser`; parsing alone neither generates nor runs tests.
2. Run `gherkin-ir-dry-checker` on the IR and review repeated or over-parameterized structures.
3. Implement or reuse the project's entrypoint generator, runtime, and step handlers. The agent supplies setup, real application calls, and assertions in the handlers.
4. Generate thin executable test entrypoints that delegate scenario execution to the runtime and handlers. These are the acceptance tests; do not add a duplicate set of complete tests for the same pipeline.
5. Run those tests through the package's existing test framework and command. When handlers exercise the service integration boundary, the generated acceptance tests belong to that integration suite.
6. For applicable Gherkin mutation, implement or reuse a persistent adapter that runs the same tests against the supplied mutated IR. An ordinary one-shot test command does not implement this protocol.

Installing the three portable Gherkin tools does not install these project-specific components.

## Gherkin mutation

Gherkin mutation changes example values and asks the project runner whether the altered specification is detected.

- Apply the shared policy's scope and applicability rules before selecting features.
- Scenarios without `Examples` have no mutation candidates; a clean exit alone does not demonstrate mutation coverage.
- A killed mutation means the acceptance system rejected the changed behavior.
- A surviving mutation indicates weak or irrelevant examples, handlers, or assertions.
- A no-op step may belong outside the specification rather than gaining artificial example columns.
- Use [the shared mutation defaults](quality-gates.md#default-policy) and preserve manifests; never switch levels merely to bypass them.
- Report inapplicable gates as skipped and missing prerequisites for applicable gates as blocked.
- Require progress/status output during long runs.
