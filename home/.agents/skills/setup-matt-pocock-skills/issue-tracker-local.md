# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files under `.ai/specs/`; decision maps and their tickets live under `.ai/wayfinder/`.

Each spec owns its issue records and follow-up. Shared tracker configuration
defines this convention; it does not combine issues or progress across specs.

## Conventions

- One feature per directory: `.ai/specs/<feature-slug>/`
- The spec is `.ai/specs/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.ai/specs/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` within that feature, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each spec or issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create or update the corresponding local file under `.ai/specs/<feature-slug>/`.
For `to-spec`, `spec.md` is the published spec. Local publication does not create
or update external issues, comments, attachments, or labels.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. Resolve an issue number within the selected
spec's `issues/` folder; the same number may exist in another feature.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.ai/wayfinder/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.ai/wayfinder/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.ai/wayfinder/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
