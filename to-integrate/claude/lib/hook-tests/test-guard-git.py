#!/usr/bin/env python3
"""Inspect fixture strings only: no commands, hooks, network or settings activated."""
import contextlib
import importlib.util
import io
import json
import shlex
import sys
from datetime import datetime
from pathlib import Path

HOOKS = Path(__file__).resolve().parents[2] / "hooks"
sys.path.insert(0, str(HOOKS))


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, HOOKS / filename)
    obj = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj


gg = module("gg", "guard-git.py")
NOW = datetime(2026, 10, 17, 9, 5)

# (command, the branch name the command should create after the hook, or None
# when the command must be left as typed)
REWRITE_CASES = [
    ("git checkout -b fix-typo", "2026-10-17-09-05-fix_typo"),
    ("git switch -c add-x", "2026-10-17-09-05-add_x"),
    ("git switch --create refactor", "2026-10-17-09-05-refactor"),
    ("git branch discuss-pricing-model", "2026-10-17-09-05-discuss_pricing-model"),
    ("git checkout -b 2026-10-01-fix-typo", "2026-10-17-09-05-fix_typo"),
    ("git checkout -b 2026-10-17-09-05-fix_typo", None),
    ("git checkout -b main", None),
    ("git checkout fix-typo", None),
    ("git branch -d fix-typo", None),
    ("git branch -m old new", None),
    ("git branch --list", None),
]

WORKTREE_CASES = [
    ("git worktree remove --force ../wt", True),
    ("git worktree remove -f ../wt", True),
    ("git worktree remove ../wt", False),
    ("git worktree list", False),
]

PASS_CASES = [
    "gh pr create --draft", "gh pr view 1", "gh issue list", "gh api repos/x/y",
    "sh -c 'gh pr view 1'", "env GH_TOKEN=fixture gh pr list", "grep gh README.md",
    "ls -Sgh", "git push -u origin review-branch", "git push origin main",
    "git branch -d old", "git push origin --delete old",
]


def run(command):
    """(stdout decision or None, warnings list) for one command through main()."""
    warnings = []
    gg.payload = lambda: {"tool_input": {"command": command}}
    gg.warn = lambda event, findings, title: warnings.extend(findings)
    gg.derive = lambda name, now=None, _d=gg.derive: _d(name, NOW)
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        gg.main()
    decision = json.loads(out.getvalue()) if out.getvalue().strip() else None
    return decision, warnings


def rewritten_to(command):
    decision, _ = run(command)
    if decision is None:
        return None
    updated = shlex.split(decision["hookSpecificOutput"]["updatedInput"]["command"])
    return [t for t in updated if t not in shlex.split(command)][0]


def main():
    checks = [(c, rewritten_to(c) == want) for c, want in REWRITE_CASES]
    checks += [(c, bool(run(c)[1]) == want) for c, want in WORKTREE_CASES]
    checks += [(c, run(c) == (None, [])) for c in PASS_CASES]
    for label, passed in checks:
        print(f"{'ok' if passed else 'FAIL'} {label}")
    print(f"{sum(p for _, p in checks)}/{len(checks)} passed")
    return int(not all(p for _, p in checks))


if __name__ == "__main__":
    raise SystemExit(main())
