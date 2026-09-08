---
name: commit
description: "Analyze, group, and commit uncommitted changes as atomic conventional commits. Use whenever the user asks to commit changes or create commits."
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
- **Arguments**: Preserve other arguments supplied with the skill invocation.

Use this dispatch prompt:

```text
Commit uncommitted changes. Scope: {scope or "all"}. {hitl if requested} {create a CR if requested}
```

In Claude Code, dispatch `Agent(subagent_type="committer",
mode="bypassPermissions")`. In Codex, spawn the custom `committer` agent.

Report what the committer created, including commit hashes and the CR ID when
applicable.
