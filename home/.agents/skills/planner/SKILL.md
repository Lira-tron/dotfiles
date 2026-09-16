---
name: planner
description: Runs an interactive, research-driven planning workflow that turns rough ideas into approved requirements, research, design, and incremental implementation plans under .codex/specs. Use only when explicitly invoked with $planner.
---

# Planner

Turn a rough idea into durable, implementation-ready planning artifacts. Keep
the user in control at every phase boundary.

Before starting or resuming planning, read
[references/workflow.md](references/workflow.md) completely and follow it.

## Non-negotiable boundaries

- Planning only. Inspect code, configuration, tests, documentation, and other
  evidence, but do not modify production code or begin implementation.
- Use only read-only inspection commands during research. Do not run project
  builds, tests, scripts, containers, deployments, or migrations.
- Do not create code reviews or run review-creation commands.
- Do not silently advance through phase gates. Continue only after the user
  explicitly approves the current artifact or chooses the next phase.
- Record questions, answers, findings, decisions, and status as they happen.
  Do not reconstruct them from memory at the end.
- Distinguish verified facts, inferences, assumptions, and unresolved
  questions. Cite external sources and use file-and-line evidence for codebase
  findings.
- Do not overwrite a non-empty planning directory. Ask for a different path.
- Include Mermaid or PlantUML diagrams when architecture, data flow, sequence,
  or component relationships are materially clearer visually.

## Starting or resuming

For a new session, gather in one prompt:

- `rough_idea` (required): direct text, a local file, or a URL.
- `project_dir` (optional): default to
  `.codex/specs/{feature_name}/` under the current workspace, where
  `{feature_name}` is a concise kebab-case name derived from the idea.

If `SESSION.md` already exists in the selected directory, read it and the
listed artifacts, summarize the current state, and ask whether to resume from
the recorded phase. Do not restart or overwrite approved work.

## Completion

Planning is complete only when the selected artifacts are approved, the final
state is reflected in `SESSION.md`, and the planning artifacts are committed
through the `commit` skill with scope restricted to `project_dir`. Never run
`git add`, `git commit`, or `git push` directly.
