#!/usr/bin/env python3
"""Build the pinned Codex footer patch, or install an already validated build."""

import argparse
import mmap
import os
import shutil
import subprocess
import tempfile
import tomllib
from pathlib import Path


VERSION = "0.160.0"
COMMIT = "a956835d020762cb2b570053af06f643a11c0ecc"
TOOLCHAIN = "1.95.0"
UPSTREAM = "https://github.com/openai/codex.git"
SCRIPTS = Path(__file__).resolve().parent
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "codex-status"
INSTALL = Path.home() / ".local/lib/codex-status"
STOCK = Path.home() / ".toolbox/tools/codex/0.160.0.614"


def external_packages(lockfile):
    return [
        package
        for package in tomllib.loads(lockfile.read_text())["package"]
        if "source" in package
    ]


def build():
    source = CACHE / "source"
    if not source.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        cached_upstream = CACHE / "upstream"
        remote = str(cached_upstream) if cached_upstream.exists() else UPSTREAM
        subprocess.run(
            ["git", "clone", "--single-branch", "--branch", f"rust-v{VERSION}", remote, str(source)],
            check=True,
        )
        subprocess.run(["git", "-C", str(source), "remote", "set-url", "origin", UPSTREAM], check=True)
    revision = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    if revision != COMMIT:
        raise RuntimeError(f"Build cache must be at {COMMIT}; inspect {source}")

    patch = SCRIPTS / "native-status.patch"
    applied = subprocess.run(
        ["git", "-C", str(source), "apply", "--reverse", "--check", str(patch)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if applied.returncode:
        subprocess.run(["git", "-C", str(source), "apply", str(patch)], check=True)

    toolchains = subprocess.check_output(["rustup", "toolchain", "list"], text=True)
    if f"{TOOLCHAIN}-" not in toolchains:
        subprocess.run(["rustup", "toolchain", "install", TOOLCHAIN, "--profile", "minimal"], check=True)
    rust = source / "codex-rs"
    dependencies = external_packages(rust / "Cargo.lock")
    environment = {
        **os.environ,
        "CARGO_PROFILE_RELEASE_DEBUG": "0",
        "CARGO_PROFILE_RELEASE_LTO": "false",
        "CARGO_PROFILE_RELEASE_CODEGEN_UNITS": "16",
        "CARGO_BUILD_JOBS": "16",
    }
    if Path("/usr/lib64/pkgconfig/openssl.pc").exists():
        environment.update(
            OPENSSL_LIB_DIR="/usr/lib64",
            OPENSSL_INCLUDE_DIR="/usr/include",
            PKG_CONFIG_LIBDIR="/usr/lib64/pkgconfig:/usr/share/pkgconfig",
            PKG_CONFIG_PATH="",
        )
    # The release tag leaves workspace versions at 0.0.0 in Cargo.lock.
    # Cargo normalizes those local versions; external dependencies must stay pinned.
    subprocess.run(
        ["cargo", f"+{TOOLCHAIN}", "build", "--release", "-p", "codex-cli", "--bin", "codex"],
        cwd=rust,
        env=environment,
        check=True,
    )
    if external_packages(rust / "Cargo.lock") != dependencies:
        raise RuntimeError("External dependencies changed; refusing to install")
    return rust / "target/release/codex"


def install(binary):
    binary = binary.resolve()
    version = subprocess.check_output([str(binary), "--version"], text=True).strip()
    if version != f"codex-cli {VERSION}":
        raise RuntimeError(f"Expected Codex {VERSION}, got {version}")
    with binary.open("rb") as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as image:
        if image.find(b"CODEX_GIT_CONTEXT_HELPER") < 0:
            raise RuntimeError("The supplied executable does not contain the footer patch")
    files = {
        "codex-code-mode-host": STOCK / "codex-code-mode-host",
        "codex-resources/bwrap": STOCK / "codex-resources/bwrap",
        "codex": binary,
    }
    for path in files.values():
        if not path.is_file():
            raise RuntimeError(f"Missing matching runtime file: {path}")
    INSTALL.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".codex-status-", dir=INSTALL.parent) as temporary:
        staged = Path(temporary)
        for name, path in files.items():
            target = staged / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        for name in files:
            target = INSTALL / name
            target.parent.mkdir(parents=True, exist_ok=True)
            (staged / name).replace(target)
    print(f"Installed {INSTALL / 'codex'}")
    print("Restart Codex from a fresh shell, or source ~/.zshenv before resuming.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", nargs="?", type=Path, help="Install an already validated patched executable")
    arguments = parser.parse_args()
    install(arguments.binary if arguments.binary else build())
