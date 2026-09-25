# dry4go CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure dry4go
dry4go="$("$manager" path dry4go)"
```

```text
dry4go [options] [file-or-directory ...]
```

With no path, it scans `.`. Directories are recursive; `.git`, `vendor`, and `target` are skipped. The tool compares Go function and method structure after normalizing names and values.

## Options

- `--threshold N`: minimum Jaccard structural similarity; default `0.82`.
- `--min-lines N`: minimum function length; default `4`.
- `--min-nodes N`: minimum normalized syntax-node count; default `20`.
- `--format F`: `text` or `json`; default `text`.
- `--json`: alias for `--format json`.
- `--text`: alias for `--format text`.
- `-h`, `--help`: print usage.

Examples:

For the quality gate, use
[the change scope](../../quality-gates/references/change-scope.md).
Comparison files may be unchanged, but only pairs involving affected functions
belong to the gate.

```sh
"$dry4go" --json internal/changed.go internal/existing.go
```

Text output reports candidate pairs and similarity. JSON returns a `candidates` array with score, files, line ranges, and node counts.

## Exit behavior

- Exit `0`: analysis completed, whether candidates exist or not.
- Exit `1`: file scan, parse, or JSON encoding failure.
- Exit `2`: invalid CLI usage or format.

Do not use the exit code as a no-duplication assertion. Review candidates for duplicated policy or responsibility; do not merge unrelated code merely because its shape is similar.
