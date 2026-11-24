---
name: gherkin-ir-dry-checker
description: Install and use the APS gherkin-ir-dry-checker to report repeated or over-parameterized structures in parsed Gherkin JSON IR. Use for Gherkin DRY analysis, IR cleanup, or checker CLI questions.
---

# gherkin-ir-dry-checker

Read [references/cli.md](references/cli.md) before running the checker.

Run it after `gherkin-parser`. It writes a report only; inspect the report and simplify the feature where that preserves meaning. Do not treat every repeated phrase as a defect.
