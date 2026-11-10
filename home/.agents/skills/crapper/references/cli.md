# Crapper CLI and coverage

Source: https://github.com/unclebob/crapper. Check the installed `--help` after
`quality-tool ensure crapper`; installation uses an isolated Python environment.

```sh
manager="$HOME/.agents/tools/quality-gates/bin/quality-tool"
"$manager" ensure crapper
crapper="$("$manager" path crapper)"
"$crapper" --help
"$crapper" --root /path/to/project --use-existing-coverage --threshold 10 src/example.py
```

Run from the owning project. `--root` controls source resolution, coverage
discovery, and `.metrics/crap.edn`; it is not an output-only directory.

## Selection and options

- Positional existing files/directories select source. A nonexistent argument
  becomes a path-substring filter: verify paths first so a typo cannot widen scope.
- `--source-root PATH` / `-s PATH` may repeat. Avoid mixing this or `--changed`
  with explicit file selection; those modes take precedence.
- `--changed` uses Git status, not the fetched upstream comparison. Use the
  [shared inventory](../../quality-gates/references/change-scope.md) instead.
- `--use-existing-coverage` reads reports without running tests.
- `--coverage-command CMD` runs a custom coverage command from `--root`.
  Its failure can still produce a report, so capture and verify coverage separately.
- `--no-coverage` reports complexity with coverage and CRAP `N/A`; diagnostic only.
- `--threshold N` exits `2` if any computed score is strictly greater than N.
  The default has no threshold. There is no `--max-workers`, `--test-command`,
  `--lines`, or JSON-output option.

## Coverage inputs

All inputs must come from passing tests of the current source and test versions.
Use the project's existing build and environment, including Brazil or Gradle,
instead of assuming the tool's default Maven or Go runner is appropriate.

| Language | Coverage consumed | Recognized location relative to root |
| --- | --- | --- |
| Python | coverage.py LCOV | `target/coverage/python/lcov.info` |
| Go | statement-weighted Go coverprofile | `coverage.out`, `target/coverage/coverage.out`, or `target/coverage/go/coverage.out` |
| Java | JaCoCo XML method `INSTRUCTION` counts | `target/site/jacoco/jacoco.xml`; also one/two nested module levels |
| TypeScript/JavaScript | LCOV | `coverage/**/lcov.info` or `target/coverage/**/lcov.info` |
| Rust | LCOV from llvm-cov/tarpaulin | `target/coverage/rust/lcov.info` |
| Clojure | Cloverage form counts, then LCOV | `target/coverage/` |

LCOV discovery accepts `target/coverage/**/lcov.info` and `coverage/**/lcov.info`.
LCOV uses branch records within a function when present, otherwise line hits.
Python coverage XML or JSON alone is insufficient; export LCOV. If the native
report is elsewhere, copy the verified report to a recognized location while
preserving its provenance and source paths. Avoid stale competing reports.

For a Python project already using pytest and coverage.py, from its root:

```sh
project_python="/absolute/path/to/project/.venv/bin/python"
"$project_python" -m coverage run --source=src -m pytest
"$project_python" -m coverage lcov -o target/coverage/python/lcov.info
"$crapper" --use-existing-coverage --threshold 10 src/example.py
```

Adapt `--source` and the test runner to the actual layout; run each step only
after the previous one succeeds. Use the project's interpreter, not Crapper's
tool environment. A top-level-module project may use `--source=example`.

Default coverage execution may delete old reports or install missing coverage
dependencies into the target environment. Prefer independently verified project
commands and `--use-existing-coverage`.

## Results and gate decisions

The text table rounds to one decimal; `.metrics/crap.edn` rounds to four.
Neither is exact evidence at a threshold boundary. `--threshold` compares full
in-memory precision. For a function-filtered gate, use the installed Python API
(`crapper.languages.functions_in_file`, `coverage.load_bundle`, and
`analyze.analyze_files`) to retain source spans and unrounded values, or recompute
from exact complexity and coverage counts. Bind coverage to the selected paths.

EDN entries contain name, namespace, complexity, coverage percentage, and CRAP,
but omit file/line identity. Resolve entries through the parsed source inventory;
do not guess overloaded methods or duplicate names. Constructors and some nested
functions are not separate entries; record excluded or inseparable targets.

Exit `0` means analysis completed, no threshold failed, or no files were found.
Exit `1` indicates usage errors; `2` is the CRAP threshold. Other operational
errors can propagate. Missing coverage is represented as 0%, and a failed
coverage runner can still yield exit `0`. Verify completeness independently.
