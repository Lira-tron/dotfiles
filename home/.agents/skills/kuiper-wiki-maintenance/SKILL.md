---
name: kuiper-wiki-maintenance
description: "Manage the local Kuiper/BOTS knowledge wiki: add sources, request content or corrections, locate the vault, inspect logs and KiroCrew schedules, and repair the index. Use kuiper-context for domain answers and coding context."
---

# Kuiper wiki maintenance

Use the existing wiki and its public `bots-wiki` CLI. This skill locates its
maintained operating guides so they stay authoritative as the implementation changes.

## Locate and inspect

Read `~/.local/share/bots-wiki/location.json`. It records `cli`, `root`, and `index`.
Use the recorded executable's parent as `PACKAGE_ROOT` and the recorded `root` as
the data root. An explicit caller-supplied `KUIPER_WIKI_ROOT` overrides the data root;
bind it to `BOTS_WIKI_ROOT` on every command. Do not infer a root from the current
directory or search unrelated workspaces. If registration is missing or inconsistent,
ask for the package/data location; an authorized maintainer can run `reader configure`
from that package.

Read `PACKAGE_ROOT/AGENTS.md` and the relevant sections of
`PACKAGE_ROOT/context/execution.md`. Load only the task-specific guide below.
Use literal resolved paths in commands and delegated work. The examples assume
`WIKI_CLI` and `WIKI_ROOT` have been set to those verified absolute values:

```bash
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" reader status
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge status
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge read index.md
```

| Location under the data root | Purpose |
|---|---|
| `vault/index.md` | Published navigation |
| `vault/entities/`, `vault/concepts/`, `vault/journeys/`, `vault/comparisons/`, `vault/diagrams/` | Derived knowledge pages |
| `vault/SCHEMA.md` | Page metadata, evidence and linking rules |
| `config/sources.json` | Source catalog and attached checkout records |
| `vault/log.md` | Activity, newest entries first |
| `vault/meta/backlog.md` | Agent handoffs and outstanding work |
| `vault/meta/<role>/report.md` | Operational reports |
| `vault/meta/intake-staging/<request-id>/` | Unpublished review drafts |
| `build/docs/` | Generated reader manifest and chunks |
| `.bots-wiki/` | Runtime state and temporary maintenance files |

Inspect catalog/request/backlog state through the CLI; do not edit their JSON or
journals. Logs, reports and staged drafts are not admitted domain knowledge.

## Add sources or request knowledge

Source onboarding records **where evidence may be read**. Intake records **what
knowledge should be produced or corrected**. A registered source is not proof of
access, a completed crawl, or a published page.

For an exact new URL, read
`PACKAGE_ROOT/skills/bots-wiki-source-onboarding/SKILL.md`. Inspect `source list`
first to reuse existing records. Register the exact page, check its adapter and
metadata, then enable only when the source checks and requested scope allow it.
Broader crawling needs explicit approved prefixes. For a supplied local DevCentral
checkout, use `source attach-local` on the existing DevCentral record; do not create
a duplicate website source. Its tracked documentation remains documentary evidence.

```bash
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" source add URL --scope page
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" source show SOURCE_ID
```

`source check` starts source inspection and updates state. `source crawl` performs
ingestion and dispatches Discovery; use it when the user requests a crawl.
Discovery also researches relevant references during its scheduled passes.
If the user says Discovery should read the sources later, register/queue the work
without fetching the source bodies now. Report unavailable access accurately.

For a human-requested page, correction, or bounded set of outputs, read
`PACKAGE_ROOT/skills/bots-wiki-local-intake/SKILL.md` and
`PACKAGE_ROOT/context/coordination.md`. Use the review skill when drafts are ready.

```bash
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" intake new \
  --title "Document the service" --description "Requested scope and evidence" \
  --source SOURCE_ID --target entities/service.md
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" intake process REQUEST_ID
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" intake show REQUEST_ID
```

Use the actual requested targets and source IDs; repeat flags for multiple values.
Processing queues routed work and captures baselines; authors still need to fill
the staged drafts. Review `prepare` and `diff` before asking the human to approve
the exact manifest. Never self-approve, alter approval hashes, or publish changed
drafts under an old approval. Prepared requests can produce a snapshot-bound
draft CR with `intake review-cr ID --expected-manifest HASH`. The CR is a diff
view marked DO NOT MERGE; local approval still controls publication.
Use the equivalent `feedback` lifecycle for a correction request.

`publishing status` reports the default reviewer and pending commit receipts.
When configured, every validated page publication creates a scoped local Git
commit, including routine agent updates. A failed Git follow-up uses
`publishing retry RECEIPT`; it never requires republishing or staging unrelated
files. Unknown CR creation results need the operator to verify remote state and
use `publishing reconcile-review`, rather than automatically creating another CR.

## Query the published wiki

Use the shared `kuiper-context` skill for evidence handling and domain answers.
Useful maintenance checks include:

```bash
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge search "artifact permissions"
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge outline entities/service.md
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge read entities/service.md --section "Operations"
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge backlinks entities/service.md
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" knowledge view quality
```

Choose real paths/headings from search or outline. Preserve returned citations,
verification dates, warnings and truncation indicators. Use `--purpose oncall` for
on-call search/read and verify current operational state upstream before acting.
A missing/stale reader cache is a maintenance finding. Only an authorized repair
uses `knowledge refresh`, followed by `knowledge status`; refresh does not verify
claims or renew their verification dates.

## Logs, agents and schedules

Read `PACKAGE_ROOT/skills/bots-wiki-ops/SKILL.md`. Inspect the first 120 lines of
`WIKI_ROOT/vault/log.md` or search it for the relevant request/role. Read archives
under `vault/meta/log-archive/` for older work; do not rewrite or truncate history.
Maintenance sessions follow the package's activity contract with `log append`
under the operator role, including start, meaningful progress and final outcome.
Do not claim that source registration means successful ingestion.

```bash
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" fleet status
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" monitor status
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" cron plan
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" cron verify
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" agents run-state discovery
BOTS_WIKI_ROOT="$WIKI_ROOT" "$WIKI_CLI" backlog list
```

KiroCrew owns scheduled execution. Its BOTS Wiki app at `/apps/bots-wiki` links
the monitoring session and per-job execution chats. `cron trigger ROLE` requests
one existing native job; `agents run ROLE` is the separate manual path.
Persistent counters are independent of session history.

Use `cron plan` before an explicitly requested schedule change, then `cron apply`
and `cron verify`; preserve native job ownership and execution chats. Use
`monitor plan/apply` only for requested monitoring setup. `log sync-cron` imports
retained runtime outcomes and writes the activity log without running agents.
Install/troubleshoot through the package's `kirocrew-bootstrap` skill and
`bots-wiki setup`. Do not change global runtime settings merely to inspect status.

Check the CLI group's `--help` before using unfamiliar flags. Return the actual
source/request IDs, changed paths, validation results and remaining work. Distinguish
registration, checks, queued work, staged drafts, approval and publication.
