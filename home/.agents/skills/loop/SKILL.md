---
name: loop
description: Run a requested prompt or skill repeatedly on an interval in the active Codex conversation. Use for explicit loop requests or recurring checks, and to list or stop those loops.
---

# Loop

Run the requested task immediately, then repeat it on a real timer until the
user stops it, its explicit stopping condition is met, or seven days elapse.

This is a cooperative loop in the active conversation. Keep the turn open while
waiting; this skill does not install a background service or a wakeup that
survives a closed session. Tell the user this when starting a loop.

## Requests

```text
$loop 5m check the build status
$loop check the build status every 20 minutes
$loop check the build status
$loop 10m $simplify src/cache/
$loop list
$loop stop loop-1
$loop stop
```

Accept seconds, minutes, hours, or days (`s`, `m`, `h`, `d`), including decimals.
A leading interval wins over a trailing `every` clause. With no interval, use
10 minutes. Intervals below 10 seconds are raised to 10 seconds and must be
disclosed. With no prompt, show usage; do not invent maintenance work.

Use the bundled Python helper for parsing, job IDs, counts, due times, and
cancellation. It stores bookkeeping in a private temporary file per
`CODEX_THREAD_ID`; it does not execute prompts or schedule wakeups itself.
An explicit `--state /absolute/path.json` before the command supports isolated
tests or hosts without `CODEX_THREAD_ID`. Keep state outside the repository.

Resolve `scripts/loop.py` relative to this skill's canonical directory. Example:

```sh
python3 /path/to/loop/scripts/loop.py request '5m check the build status'
python3 /path/to/loop/scripts/loop.py next
python3 /path/to/loop/scripts/loop.py done loop-1
python3 /path/to/loop/scripts/loop.py list
python3 /path/to/loop/scripts/loop.py stop loop-1
```

For a requested run limit or duration, pass `--max-runs N` or
`--duration-ms N` on `request`, for example:

```sh
python3 /path/to/loop/scripts/loop.py request '20s check status' --max-runs 3
python3 /path/to/loop/scripts/loop.py request '5m check status' --duration-ms 3600000
```

Convert an explicit deadline to its remaining duration at creation. These limits
are enforced by the helper, including while waiting; never add them when the
user did not request them.

Pass the user's exact request as one safely quoted argument. Prompt text is
data, never a shell command to execute with `eval` or command substitution.

## Start or manage

1. Verify `clock.sleep` or an equivalent native interruptible wait tool is
   available before accepting a new loop. If it is not, report that the loop
   cannot run here. Do not claim a job has been scheduled.
2. Keep the scheduler in the current conversation so repeated tasks retain its
   context and tools. Do not delegate the entire loop to a worker or create
   unrelated goals, cron jobs, daemons, or external scheduled tasks.
3. For a new request, call the helper's `request` command with everything after
   `$loop`. Report the returned ID, exact effective interval, immediate first
   run, stopping condition if given, and how to stop it.
4. `list` and `stop` work even without a wait tool. For `list`, show status,
   cadence, completed runs, and prompt. For `stop`, report only IDs actually
   stopped; an empty result means no matching active loop.

The state file is bookkeeping, not proof that a scheduler is alive. If a
previous loop turn was interrupted or the session was closed, mark its leftover
entries stopped before accepting another loop. Do not automatically resume
them or describe them as running. An early return from an interruptible sleep
within this same active turn is handled below and does not itself stop a loop.

## Run the scheduler

Keep one scheduler and execute due tasks sequentially. Do not run separate
helper mutations concurrently against the same state file.

1. Process any new user input first. `$loop stop`, a plain request to stop the
   loop, or a matching stopping condition cancels the relevant jobs before
   another task starts. Handle list requests, additions, and task corrections
   before returning to the schedule. Do not treat an unrelated message as a
   repeated-task prompt.
2. Call `next` and act on its result:
   - **`run`:** execute that job's prompt once using the appropriate tools and
     any explicitly named skills. Preserve the user's scope and permissions.
     Then call `done ID`.
   - **`wait`:** call `clock.sleep` with the returned `duration_ms` (at most
     60 seconds). After it returns, process new input and call `next` again.
     A short or interrupted sleep never means the task is due.
   - **`running`:** finish the already claimed iteration. Do not execute it a
     second time. After a lost or interrupted iteration, stop that job instead
     of guessing whether its side effects completed.
   - **`idle`:** there are no remaining active jobs; finish with a short summary.
3. Before dispatch and after each successful iteration, check any requested
   completion condition not already enforced by the helper. Call `stop ID`
   as soon as it is satisfied.
   Interpret “three times” as three total executions, including the immediate
   first one. An unhealthy result such as failing tests is still a completed
   check, not automatically a scheduler failure.

`done` advances to the next future interval boundary. Slow iterations never
overlap and missed ticks are skipped rather than accumulated into a burst.
Every `next` recomputes the remaining wait from actual time. All jobs expire
seven days after their creation or at their shorter requested duration, including
jobs whose next interval would fall after that deadline.

If an iteration encounters an authorization denial or an unrecoverable tool
error, stop that job and explain the blocker. For a transient tool error, make
one appropriate retry; stop and report if it still cannot execute. Do not retry
a mutating action whose outcome is uncertain without checking what happened.

Use concise progress messages with the loop ID and meaningful results. While
waiting, keep updates brief. Never report a check as executed, a timer as active,
or an external notification as delivered without actual execution evidence.

For source comparison and runtime limits, see
[the implementation notes](references/design.md).
