---
name: commit
description: "Commit changes and regroup task-local unpushed work into atomic conventional commits. Use when the user asks to commit changes or redo commit grouping."
---

# Commit via Committer Agent

Delegate all commit work to the named `committer` agent using the current
client's subagent mechanism. The parent agent must not run `git add`,
`git commit`, or `cr` directly.

## Dispatch

Pass the user's intent to the committer:

- **Scope**: Include any requested topic, file list, or other scope. Otherwise
  use `all`.
- **HITL**: Include `hitl` when the user requests approval before committing.
- **CR**: Include `create a CR` only when the user explicitly requests one.
  For updates or retries, pass the existing CR ID, selected package ranges,
  and task evidence path, including an ID returned before a Guide failure.
  Preserve the update intent; do not turn it into another creation request.
  Apply the shared "CR footer amendments" rule in
  `~/.agents/skills/submit-cr/SKILL.md` to the requested CR.
- **Arguments**: Preserve other arguments supplied with the skill invocation.
- **History**: Read
  `~/.agents/agents/committer/unpushed-commits.md` for regrouping authority and
  boundaries. Pass the selected checkout and external artifact paths, task
  context, known base, build evidence, and any append-only or preserve-history
  instruction. Let the committer choose whether and how to regroup; do not
  force one commit or prescribe groups. Dispatch even with a clean working tree
  when the request may involve existing unpushed work.
- **Amend**: Preserve an explicit target, scope, and authorization when given.
  Task-local regrouping uses the shared history policy; other message-only
  amendments need separate authorization unless the CR footer rule applies.

Use this dispatch prompt:

```text
{Preserve the user's commit, regroup, or targeted amend request}. Scope: {scope or "all"}. Checkout: {absolute source path}. Artifacts: {absolute external path}. Task context/base: {known context}. Validation: {build evidence}. Apply ~/.agents/agents/committer/unpushed-commits.md and choose cohesive groups from the final task diff. {user history restrictions or explicit amend target} {hitl if requested} {explicit CR request and existing ID if applicable}
```

In Claude Code, dispatch `Agent(subagent_type="committer",
mode="bypassPermissions")`. In Codex, spawn the custom `committer` agent.

Report what the committer created, including commit hashes and the CR ID when
applicable. For regrouping, include replaced/dropped groups and the recovery
ref. Preserve its validation status and unresolved blockers. An incomplete
validation or draft must not be summarized as ready.
