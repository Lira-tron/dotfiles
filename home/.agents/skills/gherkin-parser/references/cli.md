# gherkin-parser CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure gherkin-parser
gherkin_parser="$("$manager" path gherkin-parser)"
```

```text
gherkin-parser <feature-file> <json-output>
```

There are no options. Exactly two positional arguments are required:

1. Input `.feature` file.
2. JSON IR output file.

The output parent directory must already exist.

Example:

```sh
mkdir -p build/acceptance/ir
"$gherkin_parser" \
  features/login.feature \
  build/acceptance/ir/login.json
```

The command parses the APS-supported Gherkin subset and writes normalized feature JSON. It does not generate executable tests, invoke step handlers, or run acceptance tests.

## Exit behavior

- Exit `0`: parse and JSON write succeeded.
- Exit `1`: input open, parse, output creation, or JSON writing failed.
- Exit `2`: wrong argument count.

This binary has no dedicated help flag; invoking it with the wrong number of arguments prints usage and exits `2`.
