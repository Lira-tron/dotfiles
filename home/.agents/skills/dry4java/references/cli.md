# dry4java CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure dry4java
dry4java="$("$manager" path dry4java)"
```

```text
dry4java [options] [file-or-directory ...]
```

With no paths, it scans `src`. Directories recursively include Java files. It normalizes declaration AST structure and compares Jaccard fingerprint similarity.

## Options

- `--threshold N`: minimum similarity; default `0.82`.
- `--min-lines N`: minimum declaration length; default `4`.
- `--min-nodes N`: minimum normalized syntax-node count; default `20`.
- `--format F`: `text` or `edn`; default `text`.
- `--edn`: alias for `--format edn`.
- `--text`: alias for `--format text`.
- `-h`, `--help`: print usage.

Examples:

For the quality gate, use
[the change scope](../../quality-gates/references/change-scope.md).
Comparison files may be unchanged, but only pairs involving affected
declarations belong to the gate.

```sh
"$dry4java" --edn src/main/java/example/Changed.java src/main/java/example/Existing.java
```

Text output reports `DUPLICATE` pairs with line ranges. EDN output provides candidate scores, locations, and node counts.

## Exit behavior

Normal completion returns success whether candidates exist or not. Unknown output format exits `2`; malformed numeric values or inaccessible/parsing failures may surface as Java exceptions and a nonzero process exit.

Do not equate exit `0` with “no duplication.” Evaluate each candidate for shared knowledge, change coupling, and ownership before editing code.
