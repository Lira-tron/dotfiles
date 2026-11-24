# Unit-test layout

When adding or updating unit tests, keep one unit-test file per source file.
Use matching basenames with the project's existing test prefix or suffix and
directory layout: `ams_client.py` maps to `test/test_ams_client.py`,
`register.go` to `register_test.go`, and `client.ts` to `client.spec.ts`.

Group scenarios for a source file in its matching unit-test file. Keep shared
fixtures in the project's existing fixture helpers and integration tests in
their established suites. Apply this organization to the tests in the task's
scope.
