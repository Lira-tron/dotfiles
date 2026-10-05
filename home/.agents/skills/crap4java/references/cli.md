# crap4java CLI

## Purpose

`crap4java` combines Java method cyclomatic complexity with JaCoCo instruction coverage:

```text
CRAP = CC^2 * (1 - coverage)^3 + CC
```

It removes stale `target/site/jacoco/` and `target/jacoco.exec`, runs Maven tests with JaCoCo, reads `target/site/jacoco/jacoco.xml`, and reports methods worst-first.

## Install and syntax

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure crap4java
crap4java="$("$manager" path crap4java)"
```

```text
crap4java
crap4java --changed
crap4java <path ...>
crap4java --help
```

- No arguments: analyze all Java files under `src/`.
- `--changed`: analyze Git-detected changed Java files under `src/`.
- File arguments: analyze those files.
- Directory arguments: analyze Java files under each directory's `src/` subtree.
- `--help`: print usage.

For multiple Maven modules, files are grouped by the nearest ancestor containing `pom.xml`; coverage is generated per module.

Examples:

For the quality gate, use explicit selected files from
[the change scope](../../quality-gates/references/change-scope.md)
and filter affected methods. Do not use a directory/default scan or an
unverified `--changed` shortcut as the scope.

```sh
"$crap4java" src/main/java/example/Service.java
"$crap4java" module-a/src/main/java/example/A.java module-b/src/main/java/example/B.java
```

## Output and exit behavior

Missing JaCoCo XML produces a warning and `N/A` coverage. Reports are sorted by descending CRAP.

- Exit `0`: analysis completed and maximum CRAP is `<= 10.0`, or no Java files were selected.
- Exit `1`: invalid CLI usage.
- Exit `2`: at least one method exceeds the installed `10.0` threshold.

The tool has no custom test-command option. If its Maven coverage pipeline does not match the project, report it as unsupported rather than claiming a valid result.
