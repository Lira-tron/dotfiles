---
name: code-finalizer
description: Finalize completed development by selecting relevant checks and parallel reviews before CR submission.
disable-model-invocation: true
---

# Code finalizer

Read `~/.agents/skills/code-finalizer/SKILL.md` and follow the shared workflow.
Resolve `~` from the user's home. It owns selection, evidence reuse, review
coordination, checkpoint requirements, and readiness.

Run only when explicitly requested, including through an explicitly requested
workflow's final stage. Use Claude Code's `/simplify` capability only when
selected, and the named committer where the shared workflow calls for it.
Preserve the caller's review-only and no-commit restrictions.
