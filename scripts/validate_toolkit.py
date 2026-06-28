#!/usr/bin/env python3
"""Structural validator / test harness for the `toolkit` extension.

Usage:
  validate_toolkit.py manifest          # validate extension.yml only
  validate_toolkit.py command <name>    # validate one command file
  validate_toolkit.py all               # manifest + all command files
"""
import re
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
EXT = REPO / "extensions" / "toolkit"
MANIFEST = EXT / "extension.yml"

NAME_RE = re.compile(r"^speckit\.[a-z0-9-]+\.[a-z0-9-]+$")

EXPECTED_NAMES = [
    "speckit.toolkit.tick-checklist",
    "speckit.toolkit.resolve-checklist",
    "speckit.toolkit.validate-plan",
    "speckit.toolkit.validate-testing",
    "speckit.toolkit.validate-tasks",
    "speckit.toolkit.research",
]

# Per-command required substrings (case-insensitive). Each command task turns
# its row green by including these markers in the command body.
CONTENT_MARKERS = {
    "speckit.toolkit.tick-checklist": ["$ARGUMENTS", "check-prerequisites", "- [x]", "spec.md"],
    "speckit.toolkit.resolve-checklist": ["$ARGUMENTS", "AskUserQuestion", "batches of 5", "- [x]"],
    "speckit.toolkit.validate-plan": ["$ARGUMENTS", "check-prerequisites", "plan.md", "cross-reference"],
    "speckit.toolkit.validate-testing": ["$ARGUMENTS", "plan.md", "Domain-Driven Design", "red-green-refactor", "Playwright"],
    "speckit.toolkit.validate-tasks": ["$ARGUMENTS", "tasks.md", "Domain-Driven Design", "red-green-refactor", "Playwright"],
    "speckit.toolkit.research": ["$ARGUMENTS", "Path A", "Path B", "load-bearing", "version", "parallel"],
}

errors = []


def fail(msg):
    errors.append(msg)


def load_manifest():
    if not MANIFEST.exists():
        fail(f"manifest missing: {MANIFEST}")
        return None
    data = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
    return data


def validate_manifest():
    before = len(errors)
    data = load_manifest()
    if data is None:
        return
    if data.get("schema_version") != "1.0":
        fail('schema_version must be "1.0"')
    ext = data.get("extension", {})
    for field in ("id", "name", "version", "description", "author", "repository", "license"):
        if not ext.get(field):
            fail(f"extension.{field} missing")
    if ext.get("id") != "toolkit":
        fail('extension.id must be "toolkit"')
    if not data.get("requires", {}).get("speckit_version"):
        fail("requires.speckit_version missing")
    cmds = data.get("provides", {}).get("commands", [])
    names = [c.get("name") for c in cmds]
    if names != EXPECTED_NAMES:
        fail(f"provides.commands names mismatch.\n  expected: {EXPECTED_NAMES}\n  got:      {names}")
    for c in cmds:
        name, file = c.get("name"), c.get("file")
        if not NAME_RE.match(name or ""):
            fail(f"name fails regex: {name!r}")
        if not c.get("description"):
            fail(f"description missing for {name}")
        if file != f"commands/{name}.md":
            fail(f"file path for {name} should be 'commands/{name}.md', got {file!r}")
    if len(errors) == before:
        print(f"OK: manifest ({len(cmds)} commands)")


def validate_command(name):
    before = len(errors)
    if name not in CONTENT_MARKERS:
        fail(f"unknown command: {name}")
        return
    path = EXT / "commands" / f"{name}.md"
    if not path.exists():
        fail(f"command file missing: {path}")
        return
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        fail(f"{name}: missing YAML front matter")
    fm_end = text.find("---", 3)
    front = text[3:fm_end] if fm_end != -1 else ""
    if "description:" not in front:
        fail(f"{name}: front matter missing description")
    low = text.lower()
    for marker in CONTENT_MARKERS[name]:
        if marker.lower() not in low:
            fail(f"{name}: missing required content marker {marker!r}")
    if len(errors) == before:
        print(f"OK: command {name}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    mode = sys.argv[1]
    if mode == "manifest":
        validate_manifest()
    elif mode == "command":
        if len(sys.argv) < 3:
            print("usage: validate_toolkit.py command <name>")
            sys.exit(2)
        validate_command(sys.argv[2])
    elif mode == "all":
        validate_manifest()
        for n in EXPECTED_NAMES:
            validate_command(n)
    else:
        print(f"unknown mode: {mode}")
        sys.exit(2)
    if errors:
        for e in errors:
            print(f"FAIL: {e}")
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
