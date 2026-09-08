---
name: submit-cr
description: "Create or update a CRUX code review for the current package"
---

# Submit Code Review

When asked to create a CR, submit for review, or push changes for review:

## Never publish — the user publishes

**Never publish a CR revision. The user always does that themselves.** Do NOT
pass `--publish` or `--auto-publish` to `cr`, and never publish through the web
UI. Every `cr` invocation — creating a CR or updating an existing one — must
include `--guided --no-auto-publish`, leave the new revision unpublished
(PENDING), and hand it back to the user. This holds even when the user says
"update the CR", "push the changes for review", or similar: upload the revision,
then stop and tell them it is ready for them to publish. When delegating to a
subagent, pass this constraint through explicitly.

The global CR preference `arguments.guided=true` is also configured. Never pass
`--no-guided`; continue passing `--guided` explicitly as defense in depth.

## Pre-Flight Checks

1. **Ensure build passes** — Run `brazil-build release` and confirm success
   before creating a CR.
2. **Check sync with remote** — Verify your branch includes all remote commits.
   If diverged, warn the user and ask whether to continue or sync first.

## Creating the CR

4. **Check for CR template** — Look for `.crux_template.md` in the package
   directory. If it exists, use it as the description template.
5. **Run the cr command**:
   ```bash
   cr --guided --no-auto-publish --summary "[PackageName] feat: description" --description "## What changed\n\n## Why\n\n## Testing\n"
   ```
   - For multiple packages:
     `cr --all --guided --no-auto-publish --summary "[PackageName + N more] summary"`
   - To link a SIM ticket: `cr --issue TASK-ID`
   - To assign reviewers: `cr --reviewers "alias1,alias2"`

`--guided` generates the CR's **Guide** tab. If the package contains
`CR_GUIDE_STEERING.md`, guide generation applies it automatically.

## Description rules

**Never reference local-only paths in the CR description.** Reviewers see only
the rendered CRUX page; a path on the developer's machine is a dangling
reference. This includes:

- Files under `/workplace/...`, `/home/...`, `~/knowledge/...`, dotfiles repos,
  or any per-machine checkout location
- Build/coverage logs under `/tmp/...`
- Spec or design files that live only in a personal knowledge store

If a spec, design doc, or ticket needs to be referenced, link the **shared URL**
(Quip, internal wiki, Taskei task) rather than the local path. Summarize the
relevant context inline so the description stands on its own.

When delegating CR creation to a subagent, pass this constraint through
explicitly in the prompt — subagents will not infer it.

## Updating an Existing CR

```bash
cr -r CR-XXXXXXXX --guided --no-amend --no-auto-publish
```

Use `--no-amend` so the local commits and their `CR:` footers are not rewritten.
Leave the revision for the user to publish.

## CR Title Format

- Single package: `[PackageName] <commit subject>`
- Multiple packages: `[PackageName + N more] <summary up to 80 chars>`

## References

- CRUX docs: https://docs.hub.amazon.dev/docs/crux/index.html
- CR CLI guide: https://docs.hub.amazon.dev/docs/crux/cli-guide/index.html
- Code Review Guide:
  https://docs.hub.amazon.dev/crux/user-guide/cr-guide/
