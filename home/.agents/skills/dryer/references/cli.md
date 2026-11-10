# Dryer CLI

Source: https://github.com/unclebob/dryer. Run the installed `--help` before
relying on unfamiliar flags.

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure dryer
dryer="$("$manager" path dryer)"
"$dryer" --root /path/to/project --edn src/changed.py src/comparison.py
```

## Options and selection

| Option | Meaning |
| --- | --- |
| `--root PATH` | Project root and owner of `.metrics/dry.edn`; defaults to cwd |
| `--source-root PATH`, `-s PATH` | Alternate discovery root; repeatable |
| `--changed` | Git-status files only; omits unpushed commits and unchanged comparison files |
| `--threshold N` | Minimum similarity; default `0.82` |
| `--min-lines N` | Minimum candidate source lines; default `4` |
| `--min-nodes N` | Minimum normalized syntax nodes; default `20` |
| `--format text\|edn` | Report format; default `text` |
| `--edn`, `--text` | Format shortcuts |

There is no JSON or worker-count option. Existing positional paths select
files/trees; nonexistent arguments become substring filters. Verify paths
first. Use explicit files from the
[captured scope](../../quality-gates/references/change-scope.md), plus useful
comparison context, rather than `--changed` or mixed selection modes.

Discovery skips build/vendor/cache and test directories. Explicit individual
test files are supported. Explicit directories still use the normal walker.
Record small functions excluded by size cutoffs; change cutoffs only for a
justified investigation, never to suppress relevant matches.

## Languages and results

Supports Python, Go, Java, TypeScript (including TSX), Rust, and Clojure.
The current extension table does **not** include JavaScript, unlike Crapper
and Mutator. Unsupported languages need another verified project tool.

Only forms in the same language are compared. Java constructors and abstract
methods are omitted; nested functions generally belong to their enclosing
function. Clojure uses top-level forms other than `ns`.

Similarity is Jaccard overlap of structural fingerprints. Call/method names,
operators, and tree shape remain; local names, fields, and literals normalize
away. `1.0` means matching fingerprint sets, not necessarily matching behavior.

Text prints scores and two file/line spans. EDN preserves the candidate's
language, both spans, node counts, and a more precise score. Every successful
analysis overwrites `.metrics/dry.edn`; archive previous evidence before reruns.

Exit `0`: report written, including when duplicates were found. It also covers
no-source runs. Exit `1`: usage error. Exit `2`: unknown format. Inspect stderr
and expected declarations: parse warnings can leave a partial report with exit
`0`. Incomplete analysis of an affected declaration blocks that gate.
