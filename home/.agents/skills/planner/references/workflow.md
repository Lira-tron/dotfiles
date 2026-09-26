# Planner Workflow

Start with project setup. Requirements clarification and research may alternate
in any order, including research before requirements approval. The user may
return from design to either activity when new information changes the problem.
Requirements and research approval remain prerequisites for design.

## Phase 1: Establish the project

For a new planning session:

1. Resolve the rough idea from direct text, a local file, or a URL.
2. Derive a concise kebab-case feature name.
3. Resolve `project_dir`, defaulting to
   `.ai/specs/{feature_name}/` under the workspace.
4. Check whether the directory exists and contains files. Never overwrite a
   non-empty directory; ask the user for another path.
5. Propose this initial structure:

   ```text
   {project_dir}/
   |-- rough-idea.md
   |-- requirements.md
   `-- research/
   ```

6. After the user approves the structure, create it, preserve the supplied idea
   in `rough-idea.md`, initialize `requirements.md`, and update `SESSION.md`.

**Gate:** Do not choose or begin the next phase until the user confirms the
project structure.

## Phase 2: Choose the starting activity

Ask the user to choose:

- Requirements clarification (recommended default)
- Preliminary research on named questions
- Additional context before either activity

Do not choose silently. Record the choice in `SESSION.md`.

For preliminary research, go to Phase 4, then return to Phase 3 to incorporate
the findings into the requirements.

**Gate:** Wait for the user's choice.

## Phase 3: Clarify and approve requirements

Ask focused questions that materially affect scope, behavior, architecture, or
acceptance. Cover applicable concerns such as:

- users, use cases, and user experience;
- inputs, outputs, state changes, and integrations;
- edge cases and failure behavior;
- compatibility, migration, and rollout constraints;
- security, privacy, performance, scalability, and observability;
- success criteria, exclusions, and unresolved decisions.

Ask a small coherent set at a time. Suggest concrete options and tradeoffs when
the user is unsure. Never invent answers.

Append each question and answer to `requirements.md` as the conversation
progresses. Do not pre-populate answers or defer recording until the end.

When the user says clarification is complete, rewrite `requirements.md` into:

1. `Context & Problem Statement`
2. `Functional Requirements` with stable `FR-N` identifiers
3. `Non-Functional Requirements` with stable `NFR-N` identifiers
4. `Constraints & Assumptions`
5. `Out of Scope`
6. `Open Questions`
7. `Q&A History`, preserving the complete raw exchange

Present the consolidated document and revise it until the user explicitly
approves it. Update `SESSION.md` after approval.

**Gate:** Consolidated requirements must be explicitly approved before design.
Research may begin or resume before this approval to resolve open questions.

## Phase 4: Research the problem

The research phase is mandatory. When the existing evidence is already
sufficient, keep the phase brief, document why additional investigation is not
needed, and still create `research/summary.md`. Before researching, propose a
short research plan listing the questions, sources, and likely code areas.
Incorporate the user's changes and wait for approval.

### Codebase research

Inspect the actual workspace rather than inferring behavior from names or
comments. Read the applicable repository instructions and examine the relevant:

- package manifests, build configuration, and dependency declarations;
- implementation entry points, interfaces, data models, and integrations;
- tests, fixtures, mocks, and existing acceptance criteria;
- configuration, deployment, migration, and observability paths;
- history or diffs when they materially explain current behavior.

Use read-only commands and tools. Record concrete file-and-line evidence.
Do not run builds, tests, project scripts, containers, or implementation code.

### External and internal research

Use authoritative, current sources appropriate to the topic. Prefer primary
documentation, specifications, source repositories, and authenticated internal
systems over summaries. If a source is unavailable or requires authentication,
record that status; do not convert failed access into evidence of absence.

Cite every source used. Keep direct quotations short and prefer accurate
paraphrases.

### Parallel research

When topics are independent, delegate them to separate research subagents in
parallel if available. Give each subagent a narrow question and require
evidence. The main planner must review, reconcile, and synthesize their output;
subagent output is not automatically verified.

### Research artifacts

Write one focused file per topic under `research/`. Each file should contain:

- question and scope;
- sources and code locations examined;
- verified findings;
- inferences and assumptions, clearly labeled;
- alternatives and tradeoffs;
- recommendation and rationale;
- unresolved questions or unavailable evidence.

Share findings periodically rather than researching silently for a long
period. When the planned research is complete, create or update a concise
research synthesis in `research/summary.md`, present it, and revise as needed.

**Gate:** Ask whether research is sufficient or the user wants to return to
requirements clarification. Record the choice in `SESSION.md`. Research must be
confirmed sufficient before design.

## Phase 5: Iteration checkpoint

Summarize:

- requirements and their approval status;
- strongest research findings and source limitations;
- decisions made;
- assumptions and open questions.

Ask the user to choose:

- proceed to design;
- return to requirements clarification;
- conduct additional research.

If requirements change, update and reconsolidate `requirements.md`, then obtain
fresh approval before design. Research may continue while requirements are
being clarified.

**Gate:** Begin design only after requirements are approved, research is
confirmed sufficient, and the user explicitly chooses to proceed.

## Phase 6: Create and approve the design

Create `{project_dir}/design.md` as a standalone document containing:

1. `Overview`
2. `Detailed Requirements`
3. `Architecture Overview`
4. `Components and Interfaces`
5. `Data Models`
6. `Data Flow and State Transitions`, when applicable
7. `Error Handling and Failure Recovery`
8. `Security, Privacy, and Operational Considerations`, when applicable
9. `Acceptance Criteria` as concrete Given-When-Then scenarios
10. `Testing Strategy`
11. `Rollout, Migration, and Compatibility`, when applicable
12. `Appendices`

The appendices must summarize:

- technology choices and their evidence;
- research findings and source limitations;
- rejected alternatives and tradeoffs;
- assumptions and unresolved questions.

Map the design back to all approved requirement identifiers. Include diagrams
where they make relationships or sequences easier to understand. Keep the
document understandable without requiring the reader to open the research
files.

Present the design, collect feedback, and revise until explicitly approved.
If review reveals a requirement or research gap, return to the appropriate
phase and repeat its approval gate. Update `SESSION.md` after design approval.

**Gate:** Do not create the implementation plan until the design is explicitly
approved.

## Phase 7: Create and approve the implementation plan

Create `{project_dir}/plan.md` as an incremental, test-driven sequence. Put a
checklist of all steps at the top.

Prefer thin vertical slices that produce working, demonstrable behavior early.
Each step must build on prior steps, integrate its work, and avoid orphaned
code or speculative infrastructure.

Format every step as `Step N: <name>` with:

- **Objective**
- **Requirements mapping** using `FR-N` and `NFR-N`
- **Dependencies and prerequisites**
- **Affected components or likely file areas**, grounded in research
- **Implementation guidance**, without duplicating the full design
- **Test requirements**
- **Demo or observable outcome**
- **Completion criteria**

The plan must cover every approved requirement and every material design
element. Add a traceability table when coverage is not obvious.

For each step, include concrete test scenarios from every applicable category:

- happy path;
- null, empty, blank, malformed, out-of-range, and wrong-type inputs;
- minimum, maximum, exact-threshold, empty-collection, and single-element
  boundaries;
- expected error type and message, partial failures, and recovery;
- concurrency, ordering, and thread safety;
- idempotency and retry behavior;
- contracts, return types, immutability, side effects, and invariants;
- compatibility, migration, authorization, observability, or performance when
  required by the design.

Write specific scenarios, not labels such as "test error cases." Do not include
commit messages, staging commands, branch operations, or code-review steps.

Present the plan and revise it until explicitly approved. Update `SESSION.md`
after approval.

**Gate:** Do not summarize or hand off implementation until the implementation
plan is explicitly approved.

## Phase 8: Summarize the result

In the conversation, list:

- artifacts created;
- the approved approach;
- important tradeoffs and open questions;
- the first implementation step;
- suggested next actions.

Do not create a separate summary artifact.

## Phase 9: Offer an implementation handoff

Ask whether the user wants `{project_dir}/PROMPT.md` for a fresh implementation
session. If requested, keep it under 100 lines and include:

- `Objective`
- `Key Requirements`
- `Acceptance Criteria` as Given-When-Then scenarios from the approved `design.md`
- `Constraints and Out of Scope`
- `First Unit of Work`
- `References`, including the exact `project_dir`

Create no implementation code and launch no implementation process. Present the
resolved `PROMPT.md` path so the user can start the separate implementation
workflow themselves. Update `SESSION.md`.

## Phase 10: Finalize planning artifacts

After the final selected artifacts are approved:

1. Ensure `SESSION.md` reflects the completed planning state.
2. Report the artifact paths and leave the files in `project_dir`.
3. Do not create a code review. If the user asks for one, finish the planning
   workflow and direct them to a separate review workflow.

Do not stage, commit, or push planning artifacts, directly or through
delegation. Do not force-add ignored artifacts or change Git ignore rules to
include them. Completion does not require a Git repository or a commit.

## SESSION.md recovery contract

Create or overwrite `{project_dir}/SESSION.md` after every phase gate:

```markdown
# Session: {feature_name}

## Status
**Current Phase**: {precise phase and approval state}
**Last Updated**: {YYYY-MM-DD HH:MM with timezone}

## Context
{One to three sentences describing the problem and current state.}

## Artifacts
- [ ] rough-idea.md
- [ ] requirements.md
- [ ] research/
- [ ] research/summary.md
- [ ] design.md
- [ ] plan.md
- [ ] PROMPT.md

## Approvals
- Project structure: {pending or approved}
- Requirements: {pending or approved}
- Research: {pending or approved}
- Design: {pending or approved}
- Implementation plan: {pending or approved}

## Key Decisions
- {decision and concise rationale}

## Assumptions and Open Questions
- {item or "None"}

## Resume Instructions
{The exact next action and gate.}
```

Mark artifacts accurately. List key research files when useful. This file is a
concise current-state snapshot, not a chronological log.

## Recovery and simplification

- If requirements stall, offer examples, narrow the question, switch to another
  aspect, or propose targeted research.
- If evidence is unavailable, document what was attempted, the limitation, and
  the decision that remains blocked.
- If the design becomes too complex, identify the smallest end-to-end scope,
  move deferred behavior to `Out of Scope`, and return to requirements for
  approval.
- If the plan is much larger than the approved design warrants, simplify it.
  Every step and artifact must trace to an approved requirement.
