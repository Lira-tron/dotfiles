# CLI and integration

## Install and launch

```sh
uml="$HOME/.agents/tools/uml-viewer/bin/uml-viewer"
"$uml" --install
"$uml" scan --root /path/to/project --out /tmp/project-uml.json
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
"$uml" scan --root /path/to/project --unpushed --out /tmp/change-uml.json
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

Use the quality-tool manager to install the desired executable first:

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure crap4go mutate4go
"$uml" measure --root /path/to/go-module --tool crap4go -- --max-workers 4
"$uml" measure --root /path/to/go-module --tool mutate4go -- internal/store.go --max-workers 4

"$manager" ensure crap4java mutate4java
"$uml" measure --root /path/to/maven-module --tool crap4java -- src/main/java/demo/Store.java
"$uml" measure --root /path/to/maven-module --tool mutate4java -- src/main/java/demo/Store.java --max-workers 4
```

Everything after `--` is passed as literal arguments to the tool, without a shell.
Custom test commands follow the owning tool's options. For Brazil packages,
consult their actual build/test workflow; a successful syntax scan does not prove
that the stock Maven/Go test command is compatible.

`measure` snapshots source identity before execution, streams the real report,
and stores parsed results outside the project. It never initiates an installation.
Java CRAP exit 2 and Java mutation exit 3 still import their completed reports,
then preserve the failing exit. Go mutation survivors produce a failing wrapper
exit even though the upstream executable exits 0.

Results become stale when source/test inputs or root build descriptors change.
Mutation manifest footers are excluded from source fingerprints. This tracks
local inputs, not external environment/toolchain changes.
Differential no-op runs supply no new results and preserve previous snapshots.
Scan-only mutation output is not a result report.

CRAP text does not uniquely identify overloaded Java methods or identically
named functions in packages sharing the same short name. The importer rejects
ambiguous rows. Obtain an identity-preserving report or import an explicit
snapshot; never guess which method owns a score.

## Import an existing result snapshot

```sh
"$uml" import --root /path/to/project --kind crap --snapshot /tmp/crap.json
"$uml" import --root /path/to/project --kind mutation --snapshot /tmp/mutation.json
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
"$uml" policy --root /path/to/project --from /tmp/policy.json
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
