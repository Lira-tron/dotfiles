#!/usr/bin/env python3
"""Build named Lean theorems and record their transitive axiom dependencies."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess


ALLOWED_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)*")
CACHED_LAKE = Path.home() / ".cache/lean-verify/toolchains/lean-4.34.0-linux/bin/lake"


def source_hashes(project):
    result = {}
    for path in sorted(project.rglob("*")):
        if ".lake" in path.relative_to(project).parts or ".git" in path.parts:
            continue
        if path.is_file() and (path.suffix == ".lean" or path.name in {
            "lean-toolchain", "lakefile.toml", "lake-manifest.json"
        }):
            result[str(path.relative_to(project))] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def audit_source(module, theorems):
    text = f"import Lean\nimport {module}\n\n"
    for theorem in theorems:
        text += f'''run_cmd do
  let name := "{theorem}".toName
  let some (.thmInfo info) := (← Lean.getEnv).find? name
    | throwError "Expected a theorem: {{name}}"
  let axioms ← Lean.collectAxioms name
  let type ← Lean.Elab.Command.liftTermElabM do
    return (← Lean.Meta.ppExpr info.type).pretty
  let result := Lean.Json.mkObj [
    ("theorem", Lean.toJson name.toString),
    ("statement", Lean.toJson type),
    ("axioms", Lean.toJson (axioms.map Lean.Name.toString))]
  Lean.logInfo m!"LEAN_VERIFY {{result.compress}}"
\n'''
    return text


def check(project, module, theorems, out, lake, timeout):
    out.mkdir(parents=True, exist_ok=False)
    audit = out / "Audit.lean"
    audit.write_text(audit_source(module, theorems))
    evidence = {
        "schema_version": 1, "status": "blocked", "project": str(project),
        "module": module, "requested_theorems": theorems,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "allowed_axioms": sorted(ALLOWED_AXIOMS), "theorems": [], "commands": [],
    }

    def run(label, args):
        command = [lake, *args]
        record = {"command": command, "cwd": str(project), "log": f"{label}.log"}
        evidence["commands"].append(record)
        with subprocess.Popen(command, cwd=project, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True,
                              start_new_session=True) as process:
            try:
                stdout, stderr = process.communicate(timeout=timeout)
            except subprocess.TimeoutExpired as error:
                # Lake starts Lean children; stop the whole proof command.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                stdout, stderr = process.communicate()
                record["exit_code"] = None
                (out / record["log"]).write_text(stdout + stderr)
                raise RuntimeError(f"{label} timed out; no proof verdict") from error
        record["exit_code"] = process.returncode
        (out / record["log"]).write_text(stdout + stderr)
        if process.returncode:
            raise RuntimeError(f"{label} failed; inspect {record['log']}")
        return stdout

    try:
        if not lake:
            raise RuntimeError("Lake is unavailable; select a pinned toolchain with --lake")
        evidence["lean_version"] = run("version", ["env", "lean", "--version"]).strip()
        pin_file = project / "lean-toolchain"
        if pin_file.exists():
            pin = pin_file.read_text().strip()
            evidence["toolchain_pin"] = pin
            expected = pin.rsplit(":", 1)[-1]
            if expected.startswith("v") and f"version {expected[1:]}," not in evidence["lean_version"]:
                raise RuntimeError("Selected Lean does not match lean-toolchain")
        evidence["sources"] = source_hashes(project)
        run("build", ["build", f"+{module}"])
        output = run("audit", ["env", "lean", "--json", str(audit)])
        for line in output.splitlines():
            message = json.loads(line)
            text = message.get("data", "")
            if isinstance(text, str) and text.startswith("LEAN_VERIFY "):
                item = json.loads(text.removeprefix("LEAN_VERIFY "))
                item["unexpected_axioms"] = sorted(set(item["axioms"]) - ALLOWED_AXIOMS)
                evidence["theorems"].append(item)
        actual = [item["theorem"] for item in evidence["theorems"]]
        if sorted(actual) != sorted(theorems):
            raise RuntimeError("Missing or duplicate theorem audit records")
        if source_hashes(project) != evidence["sources"]:
            raise RuntimeError("Proof sources changed during the audit")
        evidence["status"] = (
            "rejected" if any(t["unexpected_axioms"] for t in evidence["theorems"])
            else "checked"
        )
    except (OSError, RuntimeError, ValueError) as error:
        evidence["error"] = str(error)
    (out / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--module", required=True)
    parser.add_argument("--theorem", action="append", required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--lake", default=shutil.which("lake") or
                        (str(CACHED_LAKE) if CACHED_LAKE.is_file() else None))
    parser.add_argument("--timeout", type=int, default=300, help="Seconds per command")
    args = parser.parse_args()
    if any(not NAME.fullmatch(name) for name in [args.module, *args.theorem]):
        parser.error("Use ASCII Lean module/theorem names with optional namespaces")
    if len(set(args.theorem)) != len(args.theorem):
        parser.error("Theorem names must be unique")
    project, out = args.project.resolve(), args.out.resolve()
    if out.is_relative_to(project):
        parser.error("--out must be outside the Lean project")
    if out.exists():
        parser.error("--out already exists; use a fresh evidence directory")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    evidence = check(project, args.module, args.theorem, out, args.lake, args.timeout)
    print(json.dumps({"status": evidence["status"], "evidence": str(out / "evidence.json")}))
    return {"checked": 0, "rejected": 1, "blocked": 2}[evidence["status"]]


if __name__ == "__main__":
    raise SystemExit(main())
