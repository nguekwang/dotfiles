#!/usr/bin/env python3
"""SessionEnd hook: writes the session's conversation to .claude/sessions/ as Markdown.

Claude Code keeps every session as JSONL under ~/.claude/projects/, but prunes
it after a retention period, so the only lasting record is one this repository
holds. The log keeps what the user sent and what Claude wrote back, and drops
thinking, tool calls, tool results and hook feedback; see
hooklib.transcript_turns for the exact filter. Credentials are masked because
the file is meant to be committed.

A resumed session rewrites its own file rather than starting a second one, so
one session is always one file.
"""

import sys

from hooklib import SESSIONS, local_time, payload, session_log_path, transcript_markdown, transcript_turns


def main():
    data = payload() or {}
    path = data.get("transcript_path")
    if not path:
        return
    turns = transcript_turns(path)
    if not turns:
        return
    sid = data.get("session_id", "")
    SESSIONS.mkdir(parents=True, exist_ok=True)
    out = session_log_path(sid, local_time(turns[0][1]))
    out.write_text(transcript_markdown(turns, sid, data.get("reason", "")), encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # a failed export must never block the session from ending
        print(f"[hook: export-transcript] {exc}", file=sys.stderr)
    sys.exit(0)
