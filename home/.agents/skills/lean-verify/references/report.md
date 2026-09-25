# Report contract

`report.json` is the handoff to another agent. `report.md` is a concise rendering
of the same findings and limitations, not a separate verdict. Preserve proof
sources, the pinned toolchain file, checker evidence, and reproduction logs
beside the report. Artifact paths and `reproduction.cwd` are relative to the
directory containing `report.json`; source paths are relative to the repository
root in `scope.json`. Source line numbers refer to the hashed snapshot.

The agent authors the semantic report; the scripts produce the Git snapshot and
Lean checker evidence. Do not present agent-authored classifications as
mechanically established facts.

## Required structure

The following is an illustrative report shape, not a result from a real project.
Replace every placeholder. Omit unused findings/properties by using empty arrays.

```json
{
  "schema_version": 1,
  "status": "findings",
  "scope": {
    "mode": "uncommitted",
    "manifest": "scope.json",
    "manifest_sha256": "<sha256>",
    "source_snapshot_current": true
  },
  "inventory": [
    {
      "path": "src/client.ts",
      "disposition": "analyzed",
      "property_ids": ["P001"],
      "reason": "Cancellation state transitions"
    }
  ],
  "properties": [
    {
      "id": "P001",
      "statement": "A final cancellation cannot be replaced by a successful result",
      "intent": "documented",
      "requirement_evidence": ["tests/client.test.ts:42"],
      "status": "counterexample",
      "subject": "model",
      "sources": [
        {
          "path": "src/client.ts",
          "line_start": 80,
          "line_end": 110,
          "sha256": "<sha256>"
        }
      ],
      "model_mapping": [
        {
          "lean_definition": "Verification.step",
          "source": "src/client.ts:80-110",
          "correspondence": "Maps each event handler to its state update"
        }
      ],
      "assumptions": ["Handlers execute atomically"],
      "omitted_semantics": ["Transport behavior outside event delivery"],
      "proof": null,
      "counterexample_evidence": null,
      "next_action": "Reproduce the late response sequence in the source test suite"
    }
  ],
  "findings": [
    {
      "id": "F001",
      "property_id": "P001",
      "kind": "model_counterexample",
      "summary": "A response can replace a final cancellation",
      "source": "src/client.ts:103",
      "trace": ["start", "cancel", "response"],
      "reproduction": {
        "status": "not_run",
        "command": null,
        "cwd": null,
        "exit_code": null,
        "evidence": []
      },
      "suggested_fix": "Inspect whether response handling needs an active-state guard",
      "regression_test": "Deliver a response after final cancellation"
    }
  ],
  "gaps": ["Counterexample has not been reproduced against TypeScript"],
  "next_actions": ["Reproduce F001 against the implementation"]
}
```

Every `scope.json` entry needs one `inventory` entry. Add relevant unchanged
production code to the inventory as `analyzed` and include its hash in
`properties[].sources`; explain that it is dependency context. Enumerate
unassessed code and excluded/generated/vendor/binary material with reasons.

`disposition`: `analyzed`, `supporting`, `excluded`, `unassessed`.
An analyzed file is not necessarily fully proved.

`intent`: `documented`, `inferred`, `ambiguous`. An ambiguous property stays an
explicit specification question even if one interpretation can be proved.

`subject`: `model` or `native_lean`. Native Lean requires reasoning about the
actual implementation declarations, not a separately rewritten model.

`properties[].status`:

- `proved`: checker evidence is `checked` for the exact named theorem; source
  correspondence and hypotheses were reviewed. The claim is limited to `subject`.
- `counterexample`: a concrete violating instance/trace exists. State whether it
  was checked in Lean, executed in the model, or reproduced in original code.
- `unproved`: no completed proof or validated counterexample.
- `blocked`: missing tool, dependency, runtime, or inaccessible required evidence.
- `stale`: a source, dependency, toolchain, or proof artifact changed.

For `proved`, `proof` must contain `theorem`, `statement`, `axioms`,
`evidence` (path to `evidence.json`), and `evidence_sha256`. Copy the checked
statement and axioms from that evidence; do not infer success from exit code alone.
Every requested property must remain represented, including rejected proofs.

For a Lean-checked counterexample witness, put an object with those same fields
in `counterexample_evidence` and keep `proof` null: proving the witness does not
prove the original property. Record `counterexample_validation` as a list drawn
from `lean_checked`, `model_executed`, and `source_reproduced`, with supporting
logs and commands. An unchecked proposed trace is a suspected finding, not yet
a validated counterexample.

`findings[].kind`: `confirmed_bug`, `suspected_bug`, `model_counterexample`,
`specification_gap`, or `model_mismatch`. A confirmed bug needs a source-level
reproduction or directly checked native Lean counterexample. Include its command,
working directory, result, and evidence. Never label proof timeout as a bug.

## Overall status and agent actions

| Status | Meaning | Consumer action |
|---|---|---|
| `findings` | At least one actionable finding; gaps may coexist | Triage confirmed bugs, reproduce suspects, resolve specification/model issues |
| `inconclusive` | No actionable finding yet; gaps or unproved/blocked/stale work remain | Finish the listed work; do not use as a passing gate |
| `checked` | Every requested property is proved with current evidence; no outstanding gaps | Retain evidence; this is not a guarantee about unspecified behavior |
| `no_changes` | Uncommitted scope contains no entries | Skip verification |
| `blocked` | The run could not perform verification | Resolve the stated dependency/environment problem |

All properties proved about a model still means model assurance, not automatic
verification of the original language. `checked` requires at least one property
and no unassessed code or unresolved scope/intent/correspondence gaps.

For fixes authorized by the user, the consuming agent should reproduce the
finding, make the smallest source change, add a regression test, rerun the
relevant proofs against updated hashes, and run the existing project quality
gates. Keep proof assurance, CRAP, and mutation results separate.
