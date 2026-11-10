# Matt Pocock Workflow Artifacts

Follow [the shared artifact rule](ai-artifacts.md) before reading or writing.
The `.ai` paths below traverse the selected checkout's link to its external
feature directory. Resolve absolute output paths from that feature directory;
keep source operations in the source checkout.

## Global defaults

Use local Markdown tracking by default. Each spec owns its issues and follow-up
in its feature directory; this shared rule contains no project task state.

Resolve each workflow setting independently:

| Setting | Optional repository override | Shared default |
| --- | --- | --- |
| Issue tracker | `.ai/config/issue-tracker.md` | [Local Markdown tracker](../skills/setup-matt-pocock-skills/issue-tracker-local.md) |
| Triage roles | `.ai/config/triage-labels.md` | [Default role names](../skills/setup-matt-pocock-skills/triage-labels.md) |
| Domain docs | `.ai/config/domain.md` | [Domain guidance](../skills/setup-matt-pocock-skills/domain.md) |

Read an override when present; otherwise use its shared default. Missing
repository configuration requires neither setup nor confirmation of defaults.
Use `/setup-matt-pocock-skills` only for requested repository customizations.
Keep external issue links as source references unless the user or an explicit
repository override selects an external tracker.

## Artifact locations

| Artifact | Location |
| --- | --- |
| Optional repository workflow overrides | `.ai/config/` |
| Feature specification | `.ai/specs/<feature>/spec.md` |
| Implementation tickets | `.ai/specs/<feature>/issues/<NN>-<slug>.md` |
| Wayfinding map and decision tickets | `.ai/wayfinder/<effort>/map.md` and `.ai/wayfinder/<effort>/issues/` |
| Project glossary and ADRs | `.ai/domain/GLOSSARY.md` and `.ai/domain/adr/` |
| Multiple domain contexts | `.ai/domain/GLOSSARY-MAP.md`, pointing into `.ai/domain/contexts/<context>/` |
| Research and exploration notes | `.ai/research/<topic>/` |
| Code and architecture review artifacts | `.ai/reviews/<topic>/` |
| Handoff documents | `.ai/handoffs/<timestamp>-<topic>.md` |
| Questionnaires | `.ai/questionnaires/<topic>.md` |
| Standalone prototypes and prototype evidence | `.ai/prototypes/<topic>/` |
| Diagnostic captures | `.ai/debug/<topic>/` |
| Rejected-feature records | `.ai/triage/out-of-scope/` |
| Retrospective notes, when saved | `.ai/retro/` |
| Teaching workspace and its lessons, references, and assets | `.ai/teaching/<topic>/` |
| Generated human-run wizards | `.ai/wizards/<topic>.sh` |

An explicitly selected external tracker follows its configured workflow; these
paths still govern local artifacts.

For domain terminology, follow `.ai/domain/GLOSSARY-MAP.md` when it exists;
otherwise read `.ai/domain/GLOSSARY.md`. Include both system-wide ADRs and the
ADRs for the selected context.

Read existing project documentation and explicitly referenced older artifacts
as context. Save new local artifacts in the appropriate directory above.
Preserve older files unless their migration was requested.

Read `.ai/` explicitly, including when Git ignores it. Reuse relevant existing
artifacts, and report the paths written. Pass absolute artifact paths to
subagents; shared exploration notes belong in the selected integration
feature directory's `research/` so every implementer can read the same source.

Keep native skill installations, `AGENTS.md`, `CLAUDE.md`, application source,
tests, and tool-required configuration in their normal locations. A prototype
that must mount inside an existing application keeps its required route there;
its standalone demos, captures, and decision notes use `.ai/prototypes/`.

When updating workflow skills, preserve their reference to this shared rule and
its default resolution instead of copying defaults into each repository.
