---
name: mycli-operator
description: Operate Amazon's `my` CLI reliably across its changing command surface. Use whenever running or composing `my` commands, interpreting output, handling authentication, debugging failures, or performing writes. Complements the vendor MyCli skill; do not use for implementing MyCli source changes.
---

# MyCli Operator

Use the vendor `mycli` skill for service-specific workflows. Apply these cross-cutting rules to every `my` invocation.

## Discover the live contract

1. Run `my --version` before the first `my` operation in a session.
2. Use the installed CLI as the execution source of truth:
   - `my --help` for commands.
   - `my <command> --help` for subcommands.
   - `my <command> <subcommand> --help` for exact flags and output shape.
3. Treat examples in skills, README files, and source as illustrative until current help confirms them. MyCli changes frequently.
4. `my --schema` emits a large plain-text help tree, not JSON. Search or slice it as text; do not pipe it to `jq`.
5. If a known command is missing, inspect `my self list-commands --command <command>`. Use `my self set-command` or `reset-command` only when the user asks to change availability; never edit `~/.mycli/settings.json` directly.

## Read and interpret results

- Prefer the narrowest service-specific command. Apply server-side filters, limits, date ranges, and status filters before local processing.
- Structured results are JSON; commands whose product is text emit raw text. Use `jq` only after confirming the command returns structured data.
- Treat `Output (partial)` as a shape hint. Verify fields used for joins, decisions, or user-facing claims against the live response.
- For an exhaustive request, follow every pagination token, offset, page, or `truncated` indicator. Otherwise state the limit or that the result is partial.
- Check the exit code and stderr. Never reinterpret a failed request as an empty result.
- Filter large responses before returning them to the model or user. Preserve IDs, titles, status, timestamps, and fields needed to support the answer.

## Authentication and secrets

- Follow the current subcommand help or routed vendor reference. Prefer implicit Midway authentication when the command supports it.
- When an explicit auth token is required, keep it in a shell variable and reuse it only within the needed session. Never print, quote back, persist, or place tokens in generated files, telemetry, command examples, or user-visible output.
- On authentication failure, report the exact remedy from stderr and retry after the required Midway, profile, or membership step. Do not guess credentials or switch identities.

## Mutations

MyCli has no universal confirmation gate. `dangerous: true` is metadata used by integrations; direct CLI and HTTP/MyGui calls can mutate immediately, and help does not consistently expose that metadata.

Determine risk by effect, not by the subcommand verb. Mutations include external writes and local side effects such as messages, comments, approvals, merges, submissions, uploads, downloads, generated files, command settings, browser actions, credentials, launches, and deletions.

For an authorized mutation:

1. Read the exact target and current state when practical.
2. Inspect the exact subcommand help.
3. Use `--dry-run` only when that help advertises it; MyCli has no global dry-run flag.
4. Confirm the resolved target and payload before high-impact actions such as send, submit, publish, merge, approve, cancel, delete, production changes, credential changes, purchases, or giveaways.
5. Execute once, then re-read the target or returned status to verify the effect.

Never trigger a mutation from page load, polling, speculative exploration, or a broad search pipeline. The same rules apply through `my --http`, MyGui, and `my --mcp`.

## Compose workflows

- Use a direct command for a single-service lookup.
- Run independent read-only calls in parallel when several sources are genuinely relevant.
- Generate a Bun pipeline only when joins, ranking, pagination, or branching materially improve the result. Validate every command and flag first; do not copy a vendor-reference pipeline without checking current help.
- Pass user values as arguments, not interpolated shell syntax. Do not use `eval`, expose tokens, or persist sensitive response bodies.
- Use MyCli by default when it covers the operation. Do not ask the user to choose merely because an overlapping MCP tool exists. Switch only for a missing capability, a verified MyCli failure, or an explicit user preference, and disclose the switch.

## Recover from errors

Read the complete error, adjust the named option or prerequisite, and retry. Typical recovery order:

1. Recheck subcommand help for renamed or unsupported flags.
2. Check command availability with `my self list-commands`.
3. Check Midway or service-specific authentication.
4. Distinguish permission denial, no results, rate limiting, and connectivity failure.
5. If the installed binary and current source differ, use the installed binary for runnable syntax and current source only for implementation analysis.

Report what was verified, the scope and filters used, whether results were complete, and how any mutation was verified.
