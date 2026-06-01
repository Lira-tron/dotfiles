---
name: tdd-team
description: "Launch a TDD agent team pipeline — coordinates test-writer, test-reviewer, code-writer, code-reviewer, and validator teammates through RED→GREEN→REFACTOR cycles with quality gates. Manual-invocation only via /tdd-team <spec-path>. Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1."
disable-model-invocation: true
---

# TDD Agent Team — Test-Driven Implementation Pipeline

You are the team lead. You coordinate 5 specialized teammates through TDD cycles, pipelining independent tasks for throughput.

Your key design principle: **you don't relay messages during revision loops.** Agents talk directly to each other — test-writer ↔ test-reviewer, code-writer ↔ code-reviewer — and only message you at phase boundaries (when a gate passes) or when they're stuck. This keeps your context lean and the pipeline fast.

## Options

Parse from user input (defaults apply if not specified):

| Option | Values | Default | Purpose |
|--------|--------|---------|---------|
| `--commit` | `auto`, `approval`, `none` | `auto` | What to do after validation passes |
| `--split` | flag | — | Force tmux split-pane display |
| `--inline` | flag | — | Force in-process display |

Everything else is the **input** — plain text description, a file path, or a directory path.

## Step 1: Break Down the Work

Detect input type and decompose:

- **Directory** (contains plan.md, design.md, or specs): read all files, derive subtasks from plan steps
- **Single file**: read as the task description
- **Plain text**: analyze requirements, break into subtasks if non-trivial

For each subtask, capture: title, acceptance criteria (Given/When/Then), file scope (what it'll touch), and dependencies.

**Independence check**: Two subtasks are independent when they touch different files and neither uses types/interfaces defined by the other. Independent tasks can be pipelined — test-writer starts task 2 while code-writer handles task 1.

## Step 2: Spawn the Team

Create an agent team with these 5 teammates (use exact names — they message each other directly):

| Name | Agent Type | Role | Talks to |
|------|-----------|------|----------|
| `test-writer` | `tdd-test-writer` | Writes failing tests (RED) | `test-reviewer` |
| `test-reviewer` | `tdd-test-reviewer` | Gates test quality | `test-writer` |
| `code-writer` | `tdd-code-writer` | Minimal implementation (GREEN) | `code-reviewer` |
| `code-reviewer` | `tdd-code-reviewer` | Gates code quality | `code-writer` |
| `validator` | `tdd-validator` | Runs build/tests/lint, final gate | lead |

Create all subtasks in the shared task list with dependencies marked.

## Step 3: Run the Pipeline

### Pipelining

Assembly line — each teammate owns one stage, processes tasks in order:

```
test-writer:    [Task1] [Task2] [Task3]
test-reviewer:          [Task1] [Task2]
code-writer:                    [Task1] [Task2]
code-reviewer:                          [Task1]
validator:                                      [Task1]
```

When a teammate finishes its stage for a task, assign it the next unblocked task. A rejection loop on task 1 doesn't block task 2 from progressing through earlier stages.

**File conflict prevention**: A task's file scope is "locked" from the moment it enters RED until it completes COMMIT. Before assigning any agent to a new task, check if that task's file scope overlaps with ANY in-progress task (at any stage, including VALIDATE and COMMIT). If there's overlap, don't start it — wait until the conflicting task fully completes. This prevents the validator from seeing dirty state caused by another task's test-writer modifying shared files.

### Per-task flow

You kick off each phase. Within a phase, agents loop directly without you.

**At every phase transition, update the task in the shared task list** with the current stage. This is your source of truth — if the session is interrupted, you (or a fresh lead) can read the task list and resume from the last completed phase.

Stage values: `RED`, `TEST_REVIEW`, `GREEN`, `CODE_REVIEW`, `VALIDATE`, `COMMIT`, `DONE`

**Phase 1: RED**
- Update task stage → `RED`
- Message `test-writer` with full task description + acceptance criteria
- Tell it: "When done, send your tests to `test-reviewer` for review. It will either approve or send feedback directly back to you. Keep iterating with it until approved."
- Wait for `test-reviewer` to message you: "TESTS APPROVED for TASK: [title]"

**Phase 2: GREEN**
- Update task stage → `GREEN`
- Message `code-writer` with: task description, criteria, and "tests are approved and failing"
- Tell it: "When done, send to `code-reviewer`. It will approve or send feedback directly. Keep iterating until approved."
- Wait for `code-reviewer` to message you: "CODE APPROVED for TASK: [title]"
- Special case: if `code-writer` messages you with `TEST BUILD ERROR` — route to `test-writer`, then back

**Phase 3: VALIDATE**
- Update task stage → `VALIDATE`
- Message `validator` with task context
- Wait for response directly (validator always reports to lead):
  - **VALIDATION PASSED** → commit
  - **VALIDATION FAILED** → this is NOT the end. You MUST act on it immediately:
    - Read the root cause assessment
    - "test issue" → message `test-writer` with the failure details and tell it to fix, then re-enter the review loop with `test-reviewer`. When approved, re-run validator.
    - "implementation issue" → message `code-writer` with failure details, re-enter review loop with `code-reviewer`. When approved, re-run validator.
    - Do NOT clean up, shut down, or move on. The task is not done until validation passes.

**Phase 4: COMMIT**
- Update task stage → `COMMIT`
- `auto`: invoke /commit via subagent (never push)
- `approval`: ask the user
- `none`: skip

Update task stage → `DONE`. Mark task completed.

**After ALL tasks are done**: Run the `reviewer` agent on the full diff (all commits from this session). This catches cross-task issues — inconsistencies between tasks, shared patterns that diverged, or architectural concerns only visible at the whole-change level.

If the reviewer finds BLOCKER/MAJOR issues:
1. Create a new task in the shared task list: "Fix reviewer findings: [summary of issues]"
2. Include the specific findings as acceptance criteria
3. Run it through the full pipeline (RED → TEST_REVIEW → GREEN → CODE_REVIEW → VALIDATE → COMMIT)
4. After it completes, run the `reviewer` agent again on the updated diff
5. Repeat until reviewer reports no BLOCKER/MAJOR issues

This ensures fixes get the same quality gates as original implementation.

### Resuming after interruption

If you're starting a `/tdd-team` session and the shared task list already has tasks with stages set:
1. Read the task list — check each task's current stage
2. Spawn fresh teammates
3. For each incomplete task, resume from its last completed phase:
   - Stage `RED` or `TEST_REVIEW` → re-enter Phase 1
   - Stage `GREEN` or `CODE_REVIEW` → re-enter Phase 2 (tests are already passing)
   - Stage `VALIDATE` → re-enter Phase 3
   - Stage `COMMIT` → re-enter Phase 4
   - Stage `DONE` → skip

### Escalation handling

Agents self-detect when they're stuck (getting the same feedback repeatedly, can't resolve an issue). When a teammate messages you with "ESCALATING" — stop that task's pipeline and ask the user for help. Include: which task, which phase, what's been tried, and the blocking issue.

### File conflict resolution

If two tasks unexpectedly touch the same file at runtime (despite the upfront check — file scope estimates can be wrong): pause the later task immediately, let the earlier one complete, then resume.

## Step 4: Wrap Up

When all tasks complete:
- Brief summary of what was implemented
- List commits created
- Note any issues encountered
- Clean up the team

## Leading Well

**Your context stays lean**: You only see phase transitions and escalations, not every revision loop message. This is by design — the revision loops happen between agents directly.

**Kick off with full context**: When you assign a phase, include everything that agent needs (task title, criteria, file scope). They don't see your prior conversation.

**Include communication instructions**: Always tell the writer which reviewer to talk to and what to do when approved. This is critical — without it they'll just report back to you.

**Don't do the work yourself**: If you catch yourself wanting to write code or tests, delegate instead.

**Watch for degradation**: If a teammate starts producing worse output, shut it down and spawn a fresh replacement with the same name and agent type.

**Keep teammates in their lane**: Idle is fine. Don't let agents drift into another stage's work.
