---
name: gherkin-mutator
description: Install, configure, run, and interpret APS gherkin-mutator acceptance mutation testing with Go or Java project runner adapters. Use for Gherkin mutation, differential levels, persistent runner protocol, survivors, manifests, or CLI questions.
---

# gherkin-mutator

Read [references/cli.md](references/cli.md) completely before using this tool.

Use [the shared test workflow policy](../quality-gates/references/quality-gates.md#test-workflow) for APS applicability and change scope.

The mutator is language-independent, but its required persistent runner adapter must execute the generated acceptance tests for the target Go or Java project. Verify that adapter rather than substituting an ordinary one-shot test command.

Use `--level hard`, at most four workers, periodic status, and zero survivors/errors. Preserve the feature manifest and mutation stamp.
