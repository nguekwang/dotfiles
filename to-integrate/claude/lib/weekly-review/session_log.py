"""Reading the session logs under .claude/sessions/ and calling a headless Claude.

The two weekly scripts beside this module share three things: the shape of a
session log (the Markdown `export-transcript.py` writes), a ledger of the logs
already processed, and one way of running `claude -p`. A log is processed once,
whatever the outcome, so the ledger and not the output decides what is new.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SESSIONS = ROOT / ".claude" / "sessions"
TURN = re.compile(r"^## (User|Claude) \((?:\d{2}:\d{2}|-)\)\n", re.M)
CLAUDE_ARGS = [
    "claude", "-p",
    "--model", "opus",
    "--no-session-persistence",
    "--restricted",
    "--tools", "",
    "--disable-slash-commands",
    "--settings", '{"disableAllHooks":true}',
]


def meta(text):
    """`session_id` and `started` (as `YYYY-MM-DD HH:MM`) from a log's header."""
    out = {}
    for key in ("session_id", "started"):
        m = re.search(rf"^- {key}: (.+)$", text, re.M)
        out[key] = m.group(1).strip() if m else ""
    return out


def turns(text):
    """[(who, body)] in order, `who` being `User` or `Claude`."""
    parts = TURN.split(text)
    return [(parts[i], parts[i + 1].strip()) for i in range(1, len(parts), 2)]


def user_text(text):
    return "\n\n".join(body for who, body in turns(text) if who == "User")


def ledger(path):
    """The set of log names already processed, read from one name per line."""
    try:
        return {line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()}
    except FileNotFoundError:
        return set()


def record(path, name):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(name + "\n")


def unprocessed(ledger_path):
    """Session logs not in the ledger, oldest first, at most LIMIT of them."""
    done = ledger(ledger_path)
    limit = int(os.environ.get("LIMIT", "20"))
    logs = sorted(p for p in SESSIONS.glob("*.md") if p.name != "CLAUDE.md" and p.name not in done)
    return logs[:limit]


def ask(prompt, timeout=600):
    """The reply of a headless Claude, or None when the call failed.

    A failure is printed, not swallowed: the retired SessionEnd hook hid a
    nonzero exit, and nobody could tell a failed run from a run that found
    nothing.
    """
    try:
        run = subprocess.run(CLAUDE_ARGS, input=prompt, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"claude -p failed to run: {exc}", file=sys.stderr)
        return None
    if run.returncode != 0:
        print(f"claude -p exited {run.returncode}: {run.stderr.strip()[:500]}", file=sys.stderr)
        return None
    return run.stdout.strip()
