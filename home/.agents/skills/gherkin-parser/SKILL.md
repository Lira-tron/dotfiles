---
name: gherkin-parser
description: Install and use the Acceptance Pipeline Specification gherkin-parser to validate Gherkin feature files and write JSON intermediate representation. Use for Gherkin parsing, APS acceptance generation, parser errors, or CLI questions.
---

# gherkin-parser

Read [references/cli.md](references/cli.md) before running the parser.

The parser validates and converts one feature file at a time. It neither generates nor executes tests. Keep its JSON output in a project build directory and pass that IR to `gherkin-ir-dry-checker` or, when APS execution is selected, the project's acceptance generator.

For workflow selection and the agent's responsibility for test code, read [the shared execution guide](../quality-gates/references/gherkin.md). Standalone parsing does not require an acceptance generator.
