---
name: setup-matt-pocock-skills
description: "Optionally customize repository overrides for the engineering skills' global local-tracker, triage-role, and domain-doc defaults."
disable-model-invocation: true
---

Read [workflow artifact locations](../../rules/matt-pocock-artifacts.md) before reading or writing local workflow files.

# Setup Matt Pocock's Skills

The shared workflow rule already supplies usable global defaults. Missing
`.ai/config/` files do not require setup. When no repository customization is
requested, explain the resolved defaults and proceed without scaffolding files
or asking the user to reconfirm them.

For requested customizations, scaffold the repository overrides:

- **Issue tracker**: where issues live (local Markdown by default; external trackers are explicit choices)
- **Triage labels**: the strings used for the five canonical triage roles
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. For requested overrides, explore, present what you found, confirm the changes, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config`: is this a GitHub repo? Which one?
- `AGENTS.md` and `CLAUDE.md` at the repo root: does either exist? Is there already an `## Agent skills` section in either?
- `.ai/domain/GLOSSARY.md` and `.ai/domain/GLOSSARY-MAP.md`
- `.ai/domain/adr/` and any `.ai/domain/contexts/*/adr/` directories
- `.ai/config/`: does this skill's prior output already exist?
- `.ai/specs/`: a sign that a local-markdown issue tracker convention is already in use
- Is the `triage` skill installed? (a `triage` skill folder alongside this one, or `triage` in your available skills.) This decides whether Section B runs at all.
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These are present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise the resolved defaults and requested differences. Ask only about unresolved customization choices, one section at a time.

Lead each section with the recommended answer so the user can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it (Section B when `triage` isn't installed, Section C when there's no monorepo).

**Section A: Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-tickets`, `triage`, and `to-spec` read from and write to it. They need to know whether to call `gh issue create`, write a markdown file under `.ai/specs/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.

Default posture: local Markdown, with one spec and its own issues folder per feature. A Git remote or source issue link does not change that default. If the user wants a repository override, offer:

- **GitHub**: issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitLab**: issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local markdown**: issues live as files under `.ai/specs/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Other** (Jira, Linear, etc.): ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose

Record the choice in `.ai/config/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off**. Leave it off and don't raise it: a user who wants external PRs in the triage queue can flip the flag in the file later.

**Section B: Triage label vocabulary.** Use the shared default mapping unless customization is requested. Skip this section if no label override is needed or the `triage` skill isn't installed.

If a repository label override is requested and `triage` is installed, ask exactly one question:

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is. Only if the user says no, usually because their tracker already uses other names (e.g. `bug:triage` for `needs-triage`), collect the overrides so `triage` applies existing labels instead of creating duplicates.

**Section C: Domain docs.** Default to **single-context** (one `.ai/domain/GLOSSARY.md` + `.ai/domain/adr/`). This fits almost every repo; write it without asking.

Offer **multi-context** (`.ai/domain/GLOSSARY-MAP.md` pointing to per-context glossaries under `.ai/domain/contexts/`) only when exploration found monorepo signals. Then confirm which layout they want.

### 3. Confirm and edit

Show the user a draft of:

- The `## Agent skills` block to add to whichever of `CLAUDE.md` / `AGENTS.md` is being edited (see step 4 for selection rules)
- The contents of `.ai/config/issue-tracker.md`, `.ai/config/domain.md`, and `.ai/config/triage-labels.md` (the last only when `triage` is installed)

Let them edit before writing.

### 4. Write

**Pick the file to edit:**

- If `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If neither exists, ask the user which one to create; don't pick for them.

Never create `AGENTS.md` when `CLAUDE.md` already exists (or vice versa); always edit the one that's already there.

If an `## Agent skills` block already exists in the chosen file, update its contents in-place rather than appending a duplicate. Don't overwrite user edits to the surrounding sections.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `.ai/config/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `.ai/config/triage-labels.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `.ai/config/domain.md`.
```

Include the `### Triage labels` sub-block, and write `.ai/config/triage-labels.md`, only when `triage` is installed and Section B ran. When it isn't, both are omitted.

When Section B ran on GitHub or GitLab, create each configured label the tracker lacks (`gh label create` / `glab label create`).

Then write the docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [triage-labels.md](./triage-labels.md): label mapping (only if `triage` is installed)
- [domain.md](./domain.md): domain doc consumer rules + layout

For "other" issue trackers, write `.ai/config/issue-tracker.md` from scratch using the user's description.

### 5. Done

Tell the user which requested overrides were written. Other settings continue to use the shared defaults. Repository overrides can be edited later; ordinary use of the engineering skills requires no setup.
