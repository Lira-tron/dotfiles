#!/usr/bin/env python3
"""Select durable, feature-scoped artifacts for a source checkout."""

import argparse
from datetime import date, datetime, timezone
from pathlib import Path
import re
import subprocess
import sys


def checkout_root(cwd):
    cwd = Path(cwd).expanduser().resolve(strict=True)
    if not cwd.is_dir():
        raise ValueError(f"Not a source directory: {cwd}")
    result = subprocess.run(
        ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    return Path(result.stdout.strip()).resolve() if result.returncode == 0 else cwd


def package_name(checkout):
    config = checkout / "Config"
    if config.is_file():
        match = re.search(r"(?m)^\s*package\.([\w.-]+)\s*=", config.read_text())
        if match:
            return match[1]
    return checkout.name


def component(value, label):
    pattern = r"[a-z0-9]+(?:-[a-z0-9]+)*" if label == "feature" else r"[A-Za-z0-9][A-Za-z0-9._-]*"
    if not re.fullmatch(pattern, value):
        raise ValueError(f"Invalid {label}: {value!r}; use a single path component.")
    return value


def creation_date(value):
    if not re.fullmatch(r"\d{2}-\d{2}-\d{2}", value):
        raise ValueError("Use a creation date in YY-MM-DD format.")
    date.fromisoformat("20" + value)
    return value


def knowledge_root():
    return (Path.home() / "knowledge" / "ai" / "artifacts").resolve()


def feature_path(package, feature, created):
    root = knowledge_root()
    target = root / component(package, "package") / f"{creation_date(created)}-{component(feature, 'feature')}"
    if target.resolve() != target:
        raise ValueError(f"Artifact package/feature directories must not redirect through symlinks: {target}")
    return target


def selected_path(checkout, package=None, feature=None, created=None):
    link = checkout / ".ai"
    if not link.is_symlink():
        if link.exists():
            raise ValueError(f"Preserve and migrate the existing {link} before creating a feature link.")
        raise ValueError(f"No feature link at {link}; run ai-artifacts init --feature <name>.")
    target = link.resolve(strict=True)
    root = knowledge_root()
    try:
        owner, folder = target.relative_to(root).parts
    except ValueError:
        raise ValueError(
            f"{link} must point to one package/feature directory under ~/knowledge/ai/artifacts/."
        ) from None
    match = re.fullmatch(r"(\d{2}-\d{2}-\d{2})-(.+)", folder)
    if not match or not target.is_dir():
        raise ValueError(f"Invalid feature directory: {target}")
    expected = feature_path(owner, match[2], match[1])
    if package and owner != component(package, "package"):
        raise ValueError(f"{link} belongs to package {owner}, not {package}.")
    if feature and match[2] != component(feature, "feature"):
        raise ValueError(f"{link} already selects feature {match[2]}; choose the task explicitly.")
    if created and match[1] != creation_date(created):
        raise ValueError(f"{link} uses creation date {match[1]}; retain it when resuming.")
    return expected


def initialize(checkout, package=None, feature=None, created=None):
    link = checkout / ".ai"
    if link.is_symlink() or link.exists():
        return selected_path(checkout, package, feature, created)
    if not feature:
        raise ValueError("A new task needs --feature <kebab-case-name>.")
    created = created or datetime.now(timezone.utc).strftime("%y-%m-%d")
    target = feature_path(package or package_name(checkout), feature, created)
    for directory in (knowledge_root(), target.parent, target):
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    link.symlink_to(target, target_is_directory=True)
    return target


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "path", "contains"))
    parser.add_argument("--cwd", type=Path, default=Path.cwd(), help="source checkout or a directory inside it")
    parser.add_argument("--package", help="explicit package/repository owner; defaults to Config or the Git root name")
    parser.add_argument("--feature", help="feature slug, required for a new link")
    parser.add_argument("--date", help="original creation date, YY-MM-DD; defaults to today for a new link")
    parser.add_argument("--file", type=Path, help="contains: check whether this file resolves inside the selected feature")
    args = parser.parse_args(argv)
    try:
        checkout = checkout_root(args.cwd)
        package = component(args.package, "package") if args.package else None
        if args.command == "contains":
            if args.file is None:
                parser.error("contains requires --file")
            target = selected_path(checkout, package, args.feature, args.date)
            candidate = args.file.expanduser()
            if not candidate.is_absolute():
                candidate = args.cwd.expanduser() / candidate
            return 0 if candidate.resolve().is_relative_to(target) else 1
        operation = initialize if args.command == "init" else selected_path
        print(operation(checkout, package, args.feature, args.date))
    except (OSError, ValueError) as error:
        print(f"ai-artifacts: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
