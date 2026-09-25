# gherkin-ir-dry-checker CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure gherkin-ir-dry-checker
checker="$("$manager" path gherkin-ir-dry-checker)"
```

`quality-tool` also installs `ir-dry-checker` as an executable alias.

```text
gherkin-ir-dry-checker [--include-exact] <json-ir> <report-output>
```

Arguments:

- `<json-ir>`: JSON produced by `gherkin-parser`.
- `<report-output>`: JSON report destination; its parent directory must exist.

Option:

- `--include-exact`: include ordinary exact duplicate step text across scenarios. Without it, the report focuses on more structurally useful repetition.

Example:

```sh
"$checker" \
  build/acceptance/ir/login.json \
  build/acceptance/dry/login.json
```

The checker is report-only. It does not modify the feature or fail merely because repetition exists.

## Exit behavior

- Exit `0`: IR decoded and report written.
- Exit `1`: input, JSON decoding, output, or report writing error.
- Exit `2`: flag parsing or argument-count error.

Review findings for redundant example columns, repeated setup that belongs in `Background`, and repeated structures that obscure the behavior. Preserve repetition that improves readability or describes genuinely distinct behavior.
