---
name: commit
description: "Analyze, group, and commit uncommitted changes as atomic conventional commits. Use this skill whenever the user says 'commit', 'commit this', 'commit these changes', 'commit my changes', 'smart commit', wants their diff split into logical commits, or asks to create a commit in any way. Always use this skill for committing — never run git commit directly."
---

# Commit via Committer Agent

Delegate all commit work to the **committer** agent. Do not run `git add` or `git commit` yourself.

## Dispatch

Spawn the committer agent with `Agent(subagent_type="committer", mode="bypassPermissions")`. Pass the user's intent in the prompt:

- **Scope**: If the user specified a scope (e.g., "commit auth changes"), include it.
- **HITL**: If the user said "hitl" or wants approval before committing, include "hitl" in the prompt.
- **Arguments**: Pass any arguments from the skill invocation (e.g., "all", a file list, a topic).

### Prompt template

```
Commit uncommitted changes. Scope: {scope or "all"}.{" hitl" if approval requested}
```

## Rules

- You MUST NOT run `git add` or `git commit` directly — delegate to the committer agent.
- You MUST NOT provide commit messages — the committer determines these from the diff.
- Report back what the committer created (commit hashes).
