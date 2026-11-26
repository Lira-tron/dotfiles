"""Integration checks for the shared directory root across picker sources."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).absolute().parents[1]
CABLE = ROOT / "home/.config/television/cable"


class WorkspaceDirectoryTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.workplace = self.root / "custom projects"
        self.project = self.workplace / "example"
        self.project.mkdir(parents=True)
        self.environment = {**os.environ, "WORKPLACE_DIR": str(self.workplace)}

    def test_television_directory_sources_honor_the_override(self):
        for channel in ("herdr-workspaces.toml", "rex-workspaces.toml"):
            with self.subTest(channel=channel):
                config = tomllib.loads((CABLE / channel).read_text())
                command = next(c for c in config["source"]["command"] if c.strip().startswith("fd "))
                result = subprocess.run(
                    ["bash", "-c", command], env=self.environment, capture_output=True, text=True, check=True,
                )
                self.assertEqual(result.stdout.splitlines()[0].split("\t")[1].rstrip("/"), str(self.project))
                self.assertEqual(len(result.stdout.splitlines()), 1)

    def test_herdr_all_view_uses_the_same_directory_root(self):
        executables = self.root / "bin"
        executables.mkdir()
        snapshot = {"result": {"snapshot": {
            "workspaces": [], "layouts": [], "tabs": [], "panes": [], "agents": [],
        }}}
        helper = executables / "herdr"
        helper.write_text("#!/bin/sh\nprintf '%s\\n' " + shlex.quote(json.dumps(snapshot)) + "\n")
        helper.chmod(0o755)
        result = subprocess.run(
            ["bash", str(CABLE / "herdr-panels.sh"), "all"],
            env={
                **self.environment, "PATH": str(executables) + os.pathsep + os.environ["PATH"],
                "TELEVISION_DATA": str(self.root / "tv-data"),
            },
            capture_output=True, text=True, check=True,
        )
        self.assertIn("[dir] example\t" + str(self.project), result.stdout)
        self.assertEqual(len([line for line in result.stdout.splitlines() if line]), 1)


if __name__ == "__main__":
    unittest.main()
