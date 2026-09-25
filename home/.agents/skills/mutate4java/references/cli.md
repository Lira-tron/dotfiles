# mutate4java CLI

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure mutate4java
mutate4java="$("$manager" path mutate4java)"
```

```text
mutate4java <file.java> [options]
```

Exactly one Java source file is targeted. The tool finds its owning Maven module.

## Options

- `--scan`: list mutation sites and changed scopes without tests, coverage, mutants, or manifest writes.
- `--update-manifest`: rewrite the embedded manifest without tests or mutation.
- `--reuse-coverage`: reuse JaCoCo XML. If absent, the tool continues without coverage filtering; stale-data warnings apply.
- `--lines 12,18`: mutate only positive listed lines.
- `--since-last-run`: mutate declaration scopes changed since the embedded manifest.
- `--mutate-all`: ignore the manifest and mutate all covered sites. Do not use for the default differential gate.
- `--mutation-warning N`: warn when selected mutations exceed `N`; default `50`.
- `--max-workers N`: isolated mutation workers; default half available processors. Use at most `4`.
- `--timeout-factor N`: positive mutant timeout multiplier over baseline; default `10`.
- `--test-command CMD`: replace the default baseline/mutant test command.
- `--verbose`: print live worker progress.
- `--help`: print usage.

`--scan`, `--update-manifest`, `--lines`, `--since-last-run`, and `--mutate-all` have documented mutual exclusions. In particular, do not combine differential selectors with `--mutate-all`.

## Defaults and differential behavior

Default tests are:

```text
mvn test -DexcludeTags=no-mutate
```

Tests tagged `no-mutate` are excluded. With no manifest, all covered sites run. With a manifest, normal execution automatically selects changed declaration scopes. A successful clean run writes the embedded manifest; never edit it manually.

Coverage is generated with JaCoCo unless a custom test command is supplied. A custom command causes sites to be treated as covered unless reusable external coverage is already available.

Current mutations include booleans, comparisons, equality, arithmetic, `&&`/`||`, unary removal, `0`/`1`, and replacing reference-valued rvalues with `null`.

## Recommended sequence

Capture [the change scope](../../quality-gates/references/change-scope.md)
first. Replace the example line numbers below with its current added/modified
production lines. Do not execute mutation if that set is empty.

```sh
"$mutate4java" src/main/java/example/Service.java --scan
"$mutate4java" src/main/java/example/Service.java \
  --lines 12,18 \
  --max-workers 4 \
  --verbose
```

Use `--test-command` only after verifying it runs the owning module's real focused tests.

## Exit behavior

- Exit `0`: all executed mutants killed, or no covered sites selected.
- Exit `1`: CLI usage error.
- Exit `2`: baseline tests failed.
- Exit `3`: one or more mutants survived.

Uncovered sites are skipped and reported; they are coverage findings, not killed mutants.
