#!/usr/bin/env python3
"""Shared helpers for this repository's Claude Code hooks.

Every hook reads one JSON payload on stdin and writes at most one decision
object on stdout. The two strengths this repository uses map onto that protocol
as follows, and the choice between them is the rule's coverage, not its
importance:

- deny  -- the rule's whole condition is mechanically decidable, so a violation
           is a fact. Stops the tool call.
- warn  -- a pattern catches the notation while the judgement it serves stays
           with the model. Never stops the call; the finding is handed to the
           model as context so it can fix what it actually wrote.

A hook that has nothing to say prints nothing and exits 0.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOOKS = Path(__file__).resolve().parent

# The language audio from bronze, kept as received under silver-lake/languages/;
# the notes, audio and documents from notes/languages/ beside it stay editable.
AUDIO_PARTS = {"french-verb", "french-vocabulary", "portuguese", "phonetics", "main.md"}


def language_audio(parts):
    """True when a repository-relative path (as parts) is the language audio, at or under one of its entries."""
    return parts[:2] == ("silver-lake", "languages") and len(parts) > 2 and parts[2] in AUDIO_PARTS


def hook_name():
    """The running hook's name: `sys.argv[0]` under .claude/hooks/, extension dropped."""
    path = Path(sys.argv[0]).resolve()
    try:
        rel = path.relative_to(HOOKS)
    except ValueError:
        rel = Path(path.name)
    return str(rel.with_suffix(""))


def tag(text):
    """Prefix a message with `[hook: <name>]`, so the reader sees which hook spoke."""
    return f"[hook: {hook_name()}] {text}"


def payload():
    """The hook payload, or None when stdin carries nothing usable."""
    try:
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return None


def target_paths(data):
    """(relative path, absolute path) for a file-touching tool call.

    The path is resolved against the call's `cwd` and returned relative to the
    repository. (None, None) means it lies outside this repository, where none
    of these rules apply: a hook must not police the rest of the filesystem.
    """
    ti = data.get("tool_input") or {}
    raw = ti.get("file_path") or ti.get("notebook_path") or ""
    if not raw:
        return None, None
    base = Path(data.get("cwd") or ROOT)
    try:
        resolved = Path(os.path.abspath(os.path.join(base, os.path.expanduser(raw))))
        rel = resolved.relative_to(ROOT)
    except (ValueError, OSError):
        return None, None
    return rel, ROOT / rel


def is_command(skill_md):
    """True for a skill that is a slash command: `disable-model-invocation: true`
    in its frontmatter. A skill whose description starts with "Retired." is a
    pointer, not something to run, so it is not one."""
    head = Path(skill_md).read_text(errors="replace").split("\n---", 2)[0]
    return bool(
        re.search(r"(?m)^disable-model-invocation:\s*true\s*$", head)
        and not re.search(r"(?ms)^description:\s*(>-?\s*)?Retired\.", head)
    )


def deny(reason):
    """Refuse the tool call. The reason reaches the model, not just the user."""
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": tag(reason),
            }
        },
        sys.stdout,
    )
    sys.exit(0)


def warn(event, findings, header):
    """Hand findings to the model without stopping anything."""
    if not findings:
        sys.exit(0)
    body = tag(header) + "\n" + "\n".join(f"- {f}" for f in findings)
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": event,
                "additionalContext": body,
            },
            "suppressOutput": True,
        },
        sys.stdout,
    )
    sys.exit(0)


def context(event, text):
    """Inject text as context on a non-tool event."""
    json.dump(
        {"hookSpecificOutput": {"hookEventName": event, "additionalContext": tag(text)}},
        sys.stdout,
    )
    sys.exit(0)


def git(*args):
    """Run git inside the repository. Returns stdout, or '' on any failure.

    Read-only by construction: every caller passes a query subcommand. A hook
    must never mutate the repository it is guarding.
    """
    try:
        out = subprocess.run(
            ["git", "-C", str(ROOT), *args],
            capture_output=True,
            text=True,
            timeout=10,
        )
        return out.stdout.strip() if out.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


# ---------------------------------------------------------------- shell parsing

OPERATORS = {"&&", "||", ";", "|", "&", "\n", "(", ")"}
# Wrappers that precede the real command and must be stripped before reading it.
WRAPPERS = {"sudo", "doas", "command", "nohup", "time", "env", "xargs", "nice"}


def segments(command):
    """Split a shell command into argv lists, one per simple command."""
    import shlex

    out = []
    for line in (command or "").splitlines():
        lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        try:
            tokens = list(lexer)
        except ValueError:  # unbalanced quotes; nothing reliable to read
            continue
        current = []
        for token in tokens:
            if token in OPERATORS:
                if current:
                    out.append(current)
                current = []
            else:
                current.append(token)
        if current:
            out.append(current)
    return out


def strip_wrappers(argv):
    """Drop leading wrappers and VAR=value assignments, then basename argv[0]."""
    words = list(argv)
    while words and (words[0] in WRAPPERS or re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", words[0])):
        words = words[1:]
    if not words:
        return []
    return [Path(words[0]).name, *words[1:]]

FENCE = re.compile(r"^\s*```(\S*)")


# ------------------------------------------------------------ session transcripts

SESSIONS = ROOT / ".claude" / "sessions"

# Credentials that can surface in a conversation. A session log is committed, so
# a value matching one of these is replaced before it is written anywhere.
SECRETS = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.S),
    re.compile(r"\bsk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
    re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._~+/=-]{20,}"),
]
SECRET_ASSIGN = re.compile(
    r"(?i)\b((?:api[_-]?key|access[_-]?token|secret|password|passwd)\s*[:=]\s*)(['\"]?)[^\s'\"]{8,}\2"
)


def mask(text):
    for pattern in SECRETS:
        text = pattern.sub("[REDACTED]", text)
    return SECRET_ASSIGN.sub(r"\1\2[REDACTED]\2", text)


ASK_SUFFIX = re.compile(r"\s*Read the answers carefully.*\Z", re.S)


def demote(text):
    """Push every heading in a turn two levels down, outside code fences, so a
    turn's own sections nest under the speaker heading instead of breaking it."""
    out, fence = [], False
    for line in text.splitlines():
        if FENCE.match(line):
            fence = not fence
        elif not fence and re.match(r"^#{1,4} ", line):
            line = "##" + line
        out.append(line)
    return "\n".join(out)


def _texts(content):
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    return []


def transcript_turns(path):
    """[(role, timestamp, text)] for the conversation in a transcript JSONL.

    Kept: what the user sent, including answers given through AskUserQuestion,
    and the text Claude wrote back. Dropped: thinking, tool calls and their
    results, hook feedback and other meta turns, and sidechain (subagent) turns.
    Consecutive pieces from the same speaker are merged into one turn.
    """
    entries = []
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                try:
                    entries.append(json.loads(line))
                except ValueError:
                    continue
    except OSError:
        return []

    asks = set()
    turns = []

    def add(role, ts, text):
        text = text.strip()
        if not text:
            return
        if turns and turns[-1][0] == role:
            turns[-1] = (role, turns[-1][1], turns[-1][2] + "\n\n" + text)
        else:
            turns.append((role, ts, text))

    for e in entries:
        if e.get("isSidechain") or e.get("isMeta"):
            continue
        msg = e.get("message") or {}
        content = msg.get("content")
        ts = e.get("timestamp", "")
        if e.get("type") == "assistant":
            for b in content if isinstance(content, list) else []:
                if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "AskUserQuestion":
                    asks.add(b.get("id"))
            for t in _texts(content):
                add("assistant", ts, t)
        elif e.get("type") == "user":
            if isinstance(content, list) and any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content
            ):
                for b in content:
                    if isinstance(b, dict) and b.get("tool_use_id") in asks:
                        for t in _texts(b.get("content")):
                            add("user", ts, ASK_SUFFIX.sub("", t))
                continue
            for t in _texts(content):
                add("user", ts, t)
    return turns


def local_time(ts):
    """An ISO-8601 UTC timestamp as a local datetime, or None."""
    from datetime import datetime

    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone()
    except (ValueError, AttributeError):
        return None


def session_log_path(session_id, started):
    """The session's log file: reuse an existing one, so a resumed session
    overwrites its own log instead of starting a second file."""
    short = (session_id or "unknown")[:8].lower()
    existing = sorted(SESSIONS.glob(f"*-{short}.md"))
    if existing:
        return existing[0]
    stamp = started.strftime("%Y-%m-%d-%H%M") if started else "0000-00-00-0000"
    return SESSIONS / f"{stamp}-{short}.md"


def transcript_markdown(turns, session_id, reason=""):
    started = local_time(turns[0][1]) if turns else None
    ended = local_time(turns[-1][1]) if turns else None
    fmt = "%Y-%m-%d %H:%M"
    title = turns[0][2].splitlines()[0][:60] if turns else ""
    out = [
        f"# {mask(title)}",
        "",
        f"- session_id: {session_id}",
        f"- started: {started.strftime(fmt) if started else '-'}",
        f"- ended: {ended.strftime(fmt) if ended else '-'}",
    ]
    if reason:
        out.append(f"- end_reason: {reason}")
    for role, ts, text in turns:
        t = local_time(ts)
        who = "User" if role == "user" else "Claude"
        out += ["", f"## {who} ({t.strftime('%H:%M') if t else '-'})", "", mask(demote(text))]
    return "\n".join(out) + "\n"
