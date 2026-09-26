---
name: planner
description: Use when the user asks to create a plan, create a spec, make a plan, write or draft a plan or specification, or plan a feature, even without naming the skill, or explicitly invokes $planner. Runs an interactive, research-driven planning workflow that turns rough ideas into approved requirements, research, design, and incremental implementation plans under .ai/specs.
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
  `.ai/specs/{feature_name}/` under the current workspace, where
  `{feature_name}` is a concise kebab-case name derived from the idea.

If `SESSION.md` already exists in the selected directory, read it and the
listed artifacts, summarize the current state, and ask whether to resume from
the recorded phase. Do not restart or overwrite approved work.

## Completion

Planning is complete when the selected artifacts are approved and the final
state is reflected in `SESSION.md`. Keep planning artifacts local; do not stage,
commit, or push them, directly or through delegation. Do not force-add ignored
artifacts or change Git ignore rules to include them.
