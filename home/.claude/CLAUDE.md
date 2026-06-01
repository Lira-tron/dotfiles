# CLAUDE.md

Behavioral guidelines for all task types.

---

## 1. Investigate Before Answering

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Applies to every task — coding, design, investigation, debugging, review:

- Read the actual code, data, or system before answering. Don't infer from names, comments, or training data. Don't generalize from one file to others.
- Back every claim with something you verified — code you read, search results, tool output. Distinguish what you verified from what you're inferring.
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

## 5. Tool Error Recovery

When a tool call fails, read the error message, adjust parameters, and retry. Don't give up or guess the answer after a failed call.

---

## Git

- Always use `git -P` for commands that paginate (log, diff, show, blame, branch)
- Never run `git push`
- Never force push, never rewrite pushed commits — fix forward
- Commit early and often. Build before committing.
- Never use `git reset --hard` or `git clean`
- `git fetch` before assuming commits are local-only — the remote can advance without your awareness
- **Do not use git worktrees.** Ignore `superpowers:using-git-worktrees`.
- **Commit policy**: Never run `git add`/`git commit` directly — delegate to the **committer** agent via `/commit` or `Agent(subagent_type="committer")`. The committer handles grouping, message writing, and staging.
