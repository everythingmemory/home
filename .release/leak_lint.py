#!/usr/bin/env python3
# Copyright (c) 2026 ConcurAI
# SPDX-License-Identifier: BUSL-1.1
"""Leak lint for a released tree. Standard library only: the published repos'
CI runs this same file, from .release/ in their root.

    python3 .release/leak_lint.py [ROOT]

Fails (exit 1) on:
  - a file the release manifest (.release/manifest.txt) does not list, a
    listed file that is missing, or one whose content changed;
  - a section citation (§ and digits), a sprint tag (v and two digits) or an
    internal document name;
  - a word on the term list (.release/terms.json holds SHA-256 digests only,
    so the list itself names no one);
  - a private registry or hostname;
  - anything shaped like a key or secret.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

HERE = ".release"

RULES: list[tuple[str, re.Pattern]] = [
    ("citation", re.compile(r"§+\s?\d")),
    ("sprint-tag", re.compile(r"\bv[3-5][0-9]\b")),
    ("internal-doc", re.compile(
        r"\b(?:arch|plan|backlog|runbook|review|handoff|spike)(?:[.-][\w-]+)*\.md\b"
        r"|\b[a-z]+\.spec\b(?![.\w])"
        r"|\bplan\.v\d+\b|\b(?:runbook|handoff)\.[a-z][\w-]*"
        r"|\binternal-docs\b|\binternal-agentic\b")),
    ("private-registry", re.compile(
        r"registry\.digitalocean\.com|digitaloceanspaces\.com|ondigitalocean\.app", re.I)),
    ("private-host", re.compile(
        r"\b(?!www\.|docs\.)[a-z0-9-]+\.everythingmemory\.ai\b"
        r"|\b(?:[a-z0-9-]+\.)+concurai\.com\b", re.I)),
    ("secret", re.compile(
        r"-----BEGIN [A-Z ]*PRIVATE KEY-----"
        r"|\bAKIA[0-9A-Z]{16}\b"
        r"|\bgh[pousr]_[A-Za-z0-9]{30,}"
        r"|\bgithub_pat_[A-Za-z0-9_]{20,}"
        r"|\bsk-(?:ant-|or-|proj-)?[A-Za-z0-9_-]{24,}"
        r"|\bxox[abposr]-[A-Za-z0-9-]{10,}"
        r"|\bdop_v1_[a-f0-9]{32,}"
        r"|\bemem_[A-Za-z0-9_-]{24,}"
        r"|AGE-SECRET-KEY-1[0-9A-Z]{20,}")),
]

_WORD = re.compile(r"[A-Za-z0-9]+")


def digest(word: str) -> str:
    return hashlib.sha256(word.encode()).hexdigest()


def load_terms(path: Path) -> tuple[set[str], set[str]]:
    if not path.is_file():
        raise SystemExit(f"leak lint: {path} is missing — the term check cannot run")
    data = json.loads(path.read_text())
    return set(data.get("lower", [])), set(data.get("exact", []))


def load_manifest(path: Path) -> dict[str, str] | None:
    if not path.is_file():
        return None
    out = {}
    for line in path.read_text().splitlines():
        if line.strip():
            sha, rel = line.split("  ", 1)
            out[rel] = sha
    return out


def files_under(root: Path) -> list[str]:
    out = []
    for p in sorted(root.rglob("*")):
        rel = p.relative_to(root).as_posix()
        if rel == ".git" or rel.startswith(".git/") or not p.is_file():
            continue
        out.append(rel)
    return out


def lint(root: Path) -> list[str]:
    problems = []
    manifest = load_manifest(root / HERE / "manifest.txt")
    lower, exact = load_terms(root / HERE / "terms.json")
    present = files_under(root)
    if manifest is None:
        problems.append(f"{HERE}/manifest.txt: missing")
    else:
        for rel in present:
            if rel.startswith(HERE + "/"):
                continue
            if rel not in manifest:
                problems.append(f"{rel}: not in the release manifest")
            elif hashlib.sha256((root / rel).read_bytes()).hexdigest() != manifest[rel]:
                problems.append(f"{rel}: changed since the release")
        for rel in sorted(set(manifest) - set(present)):
            problems.append(f"{rel}: in the manifest but missing")
    for rel in present:
        if rel.startswith(HERE + "/"):
            continue
        try:
            text = (root / rel).read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for n, line in enumerate(text.splitlines(), 1):
            for name, rx in RULES:
                m = rx.search(line)
                if m:
                    shown = "…" if name == "secret" else m.group(0)
                    problems.append(f"{rel}:{n}: {name}: {shown}")
            for w in _WORD.findall(line):
                if digest(w) in exact or digest(w.lower()) in lower:
                    problems.append(f"{rel}:{n}: term: {w[0]}{'*' * (len(w) - 1)}")
    return problems


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("root", nargs="?", default=".", type=Path)
    args = ap.parse_args(argv)
    problems = lint(args.root.resolve())
    for p in problems:
        print(p)
    print(f"leak lint: {len(problems)} problem(s)", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
