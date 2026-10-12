# Matt Pocock Workflow Artifacts

Follow [the shared artifact rule](ai-artifacts.md). Resolve the paths below from
the target repository or package root; without a repository, use the working
directory. Create directories only when the workflow has something to save.

| Artifact | Location |
| --- | --- |
| Issue-tracker, triage-label, and domain configuration | `.ai/config/` |
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

Read `.ai/config/issue-tracker.md`, `.ai/config/triage-labels.md`, and
`.ai/config/domain.md` when the workflow needs them. An external issue tracker
still follows its configured workflow; these paths govern local artifacts.

For domain terminology, follow `.ai/domain/GLOSSARY-MAP.md` when it exists;
otherwise read `.ai/domain/GLOSSARY.md`. Include both system-wide ADRs and the
ADRs for the selected context.

Read existing project documentation and explicitly referenced older artifacts
as context. Save new local artifacts in the appropriate directory above.
Preserve older files unless their migration was requested.

Read `.ai/` explicitly, including when Git ignores it. Reuse relevant existing
artifacts, and report the paths written. Pass absolute artifact paths to
subagents; shared exploration notes belong in the selected integration
checkout's `.ai/research/` so every implementer can read the same source.

Keep native skill installations, `AGENTS.md`, `CLAUDE.md`, application source,
tests, and tool-required configuration in their normal locations. A prototype
that must mount inside an existing application keeps its required route there;
its standalone demos, captures, and decision notes use `.ai/prototypes/`.
