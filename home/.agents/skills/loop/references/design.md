# Loop design and source notes

Reviewed September 23, 2026.

## Source behavior

The supplied [Pi repository](https://github.com/emanuelcasco/pi-mono-extensions/tree/main#loop)
implements `/loop` with real JavaScript timers and `pi.sendUserMessage()`.
The [implementation inspected](https://github.com/emanuelcasco/pi-mono-extensions/blob/e4e047a5a203cac78f5e420c92a3115ccd2fe6bb/extensions/loop/index.ts)
was revision `e4e047a5a203cac78f5e420c92a3115ccd2fe6bb`.

Its documented contract is:

- Run immediately, then repeat.
- A leading interval takes priority over a trailing `every` clause.
- Support `s`, `m`, `h`, and `d`; default to ten minutes and clamp to ten seconds.
- Assign IDs and support listing, stopping one loop, and stopping all loops.
- Expire after seven days and clear timers on session shutdown.
- Queue follow-up prompts when the agent is busy.

This Codex adaptation retains the parsing and management behavior. Its
instructions and Python helper were written for Codex; it does not load Pi
packages or copy the TypeScript runtime.

## Runtime choice

[OpenAI documents skills](https://learn.chatgpt.com/docs/build-skills) as reusable
instructions with optional scripts. A skill does not itself register a host
timer or create a new built-in slash command. Invocation is `$loop`.

[OpenAI's scheduled-task documentation](https://learn.chatgpt.com/docs/automations)
directs users to the web or desktop app for the Scheduled management interface.
It does not document a corresponding Codex CLI scheduling interface.

The available Codex runtime exposes `clock.sleep`, an interruptible native wait
tool. The skill uses it while keeping the current conversation turn active.
The helper manages bookkeeping only: the assistant performs the task and calls
the timer. Returning a final response, closing the session, or interrupting the
turn ends this scheduler. Saved JSON does not prove a loop is running and does
not create an automatic restart.

This preserves the current conversation's tools and explicit skill calls,
including skills that need subagents. Delegating the entire scheduler to a
child can lose those capabilities. No separate model-provider configuration,
background process, OS scheduler, or daemon is installed.

## Deliberate differences

| Area | Codex adaptation |
| --- | --- |
| Background scheduling | Requires an active conversation turn; it cannot enqueue a new parent turn after that turn ends. |
| Busy or slow iterations | Execute sequentially, skip missed interval boundaries, and schedule the next future boundary. Do not accumulate an unbounded prompt queue. |
| Cancellation | Handle new user input before another iteration; stopped jobs cannot be revived by a late completion. Already issued external actions may still need their own cancellation. |
| Timer interruption | Recompute due time after every wakeup. An early wakeup is not permission to run early. |
| Requested limits | Store explicit run counts and durations in the helper so they are enforced even while waiting. Expiry prevents another iteration; it does not undo an in-flight action. |
| Prompt formatting | Preserve internal whitespace and newlines. The Pi leading-token parser joins whitespace-separated words. |
| Trailing units | Accept both `every 2h` and `every 2 hours`; the Pi implementation's expression omits the space despite its comment. |
| Counts | Track starts and completions separately, including the immediate first iteration. Pi's immediate call bypasses its recurring fire counter. |
| Errors | Stop on denied or unrecoverable actions; allow one appropriate transient retry. An ordinary unhealthy status is a completed check. |

Current [Claude Code documentation](https://code.claude.com/docs/en/scheduled-tasks)
also describes adaptive intervals and a default maintenance prompt for a bare
`/loop`. This implementation follows the supplied Pi interface: no prompt shows
usage, and no interval means ten minutes. It does not invent maintenance tasks,
adapt the cadence, or claim Claude's persistent cron/wakeup behavior.

## State and validation

Runtime state lives in a private temporary directory keyed by `CODEX_THREAD_ID`.
It is not kept inside the skill, the project, or version control. The scheduler
serializes helper operations; atomic file replacement protects complete JSON
writes but is not a lock for independent concurrent schedulers.

The helper never executes prompt text. It returns either one due job, a bounded
wait, an already running job, or an idle result. Each wait is at most sixty
seconds so user input and progress remain responsive.

Run the deterministic and CLI tests with:

```sh
python3 -B -m unittest discover -s tests -v
```

The tests cover parsing, exact prompt preservation, immediate execution,
counter accuracy, early wakeups, slow iterations, non-overlap, cancellation,
expiry, private state files, and prompt text remaining data. Live validation
also needs an actual native timer and bounded task execution; successful
parsing or skill discovery alone does not establish a working loop.
