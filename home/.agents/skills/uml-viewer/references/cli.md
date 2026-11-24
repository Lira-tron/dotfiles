# CLI and integration

## Install and launch

```sh
uml="$HOME/.agents/tools/uml-viewer/bin/uml-viewer"
AI_ARTIFACT_ROOT="$(ai-artifacts path --cwd /path/to/project)" || exit 1
mkdir -p "$AI_ARTIFACT_ROOT/uml"
"$uml" --install
"$uml" scan --root /path/to/project --out "$AI_ARTIFACT_ROOT/uml/project.json"
"$uml" serve --root /path/to/project --port 8765
```

The launcher compiles the local source with Go. The executable goes to
`${UML_VIEWER_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-tools/uml-viewer}/bin/uml-viewer`.
Compilation uses only the Go standard library. Java scanning requires `java` and
`javac` from JDK 17+; the embedded scanner is compiled into the user cache.

Run the server as a persistent command/session. It binds only to `127.0.0.1` and
prints a URL containing a session token in its fragment. The browser stores the
token for API requests. `--port 0` selects a free port.

For a remote development host, forward the printed port with SSH and open the
same localhost URL in the local browser. Do not expose the server publicly.
`status --root DIR` returns the last server URL/PID and state directory; verify
that the process is alive before treating it as a running server.

`scan` emits JSON with nodes, edges, file hashes, and an input hash. `--tests`
includes test declarations. By default, test directories, Go `_test.go` files,
hidden directories, `vendor`, `node_modules`, `target`, `build`, `out`, and
`testdata` are excluded. Recognized generated Go sources are excluded.

Go extraction includes packages, imports, types, interfaces, functions, and
receiver methods. Java includes packages, imports, classes/interfaces/records/
enums, nested classes, fields, constructors, methods, and inheritance.
This is syntax analysis, not a complete call graph or type checker. It scans Go
source across build tags/platforms; duplicate type names across variants need
scoping to a suitable source tree. Java wildcard imports, external classpaths,
and ambiguous inheritance targets remain explicitly unresolved.

## Review unpushed changes

Say: **"Use UML viewer only for my unpushed changes."**

```sh
"$uml" scan --root /path/to/project --unpushed --out "$AI_ARTIFACT_ROOT/uml/changes.json"
"$uml" serve --root /path/to/project --unpushed --port 0

# When a new branch has no upstream, choose its intended comparison branch:
"$uml" serve --root /path/to/project --unpushed --base origin/main --port 0
```

By default the baseline is the branch's configured upstream. The CLI fetches
that remote once at startup and stops if fetching fails. It compares the working
tree and index against the merge base of HEAD and the fetched baseline, then
adds nonignored untracked files. This includes local commits and uncommitted
work without treating remote-only changes on a diverged branch as your changes.
An explicitly supplied local ref/commit is used as-is, without a remote fetch.

Selection is confined to Go/Java files under `--root`. Changed tests are included
automatically. The diagram contains declarations from those files and their
containing packages/types; it is a file-focused view, not a line-by-line diff.
Direct unchanged dependencies can be shown with **Dependency context**.
Renames name the prior path; deleted files have a marker with no current source
body. Files outside normal scanner filters are still listed, but not parsed.
The source viewer displays current files on disk. If the index contains a change
that the current working file reverses, the scope lists that distinction rather
than pretending to show the staged version.

The sidebar records the baseline, merge-base SHA, local commit count, and file
statuses. The local commit count is for the branch, even when `--root` selects a
subdirectory. Git state is checked during browser polling; no recurring fetch
is scheduled. After another fetch changes the tracking ref, the review updates.
This compares against one chosen baseline, not every remote or patch-equivalent
squash/cherry-pick elsewhere.

Viewing does not run tests or quality tools. The mode does not push, commit,
stage, or edit project source.

## Browser

- Click a card for source identity and metrics; double-click to drill into it.
- Open a member to view its source at the recorded declaration.
- Search by package, symbol, or signature; external dependencies are optional.
- The viewer checks source/test changes and metric snapshots every five seconds.
  Rescan immediately refreshes the graph.
- Export JSON saves the graph. Values are observations, not a quality-gate verdict.
- Package metrics cover measured descendants only: maximum CRAP, mean reported
  coverage, and summed complexity/mutation counts. Unknown data remains unknown.
  Red indicates CRAP > 10 or survivors; amber indicates uncovered mutants.
  Individual tool/project gates can be stricter than this display threshold.

## Run and capture real metrics

Run the shared `crapper` or `mutator` skill against explicit task files and
lines. These tools write EDN under the project's `.metrics/` directory.

This **local** Go/Java viewer is distinct from the upstream viewer mentioned in
the unified tools' README files. Its `measure --tool` command still recognizes
only the legacy Go/Java executable names, and its `import` command requires the
JSON schema below. Do not invoke `measure --tool crapper` or `--tool mutator`,
or hand raw EDN to `--snapshot`.

For unified results, scan the same source version and construct an explicit
JSON snapshot from verified measurements. Match each record to a unique graph
node using parsed source identity; preserve measured source/input hashes.
Crapper EDN omits file/line identity and rounds values, so use its source-aware
API or exact raw coverage counts for ambiguous or boundary values. Mutator
snapshots carry file/span and per-site evidence; distinguish this execution
from retained history. If a mapping cannot be established, leave it unknown.

Archive raw tool output alongside the imported snapshot. Stale source/test
hashes remain stale; never attach current hashes to an older measurement.
A viewer import is visualization, not a new quality-gate verdict. This local
viewer still scans Go and Java only; Python analysis works through the unified
tool skills without implying Python graph support.

## Import an existing result snapshot

```sh
"$uml" import --root /path/to/project --kind crap --snapshot "$AI_ARTIFACT_ROOT/uml/crap.json"
"$uml" import --root /path/to/project --kind mutation --snapshot "$AI_ARTIFACT_ROOT/uml/mutation.json"
```

Schema:

```json
{
  "version": 1,
  "created_at": "2026-09-24T00:00:00Z",
  "records": [{
    "node_id": "<exact node ID from scan>",
    "file": "internal/store.go",
    "line": 12,
    "hash": "<source hash captured before the measured run>",
    "input_hash": "<graph input_hash captured before the measured run>",
    "values": {"cc": 2, "coverage": 100, "crap": 2}
  }]
}
```

Mutation values use `killed`, `survived`, and `uncovered` integer counts.
Coverage is a percentage from 0 to 100. Missing hashes are accepted but displayed
as stale/unverified. Do not attach today's hashes to an older report.
`node_id` is required when file and line alone match multiple declarations.

## Proposals and Codex requests

**New proposal** creates a separate named view. **Move into proposal group**
assigns a selected package/type to a hypothetical group. The source stays intact.
The layout policy is readable/editable through the browser or:

```sh
"$uml" policy --root /path/to/project
"$uml" policy --root /path/to/project --from "$AI_ARTIFACT_ROOT/uml/policy.json"
```

Policy fields: `proposals` is an array of `{id, name, groups, omit}`. `groups`
maps source node IDs to group names; `omit` lists hidden IDs. `levels` maps
package IDs or group names to numeric architectural levels. Edges from higher
to lower configured levels are highlighted; no architectural order is inferred.

Browser requests persist as individual files in the project-specific user cache:

```sh
"$uml" requests --root /path/to/project
"$uml" requests --root /path/to/project --ack 123456789
```

The browser offers inspection, CRAP refresh, and mutation refresh requests.
Read their target IDs from a fresh scan and apply the existing language-tool
workflow. Browser requests do not execute commands or start another Codex agent.
The user pastes **Copy handoff prompt** into this conversation to request handling.
