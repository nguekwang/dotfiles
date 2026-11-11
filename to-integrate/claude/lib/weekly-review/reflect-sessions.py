#!/usr/bin/env python3
"""Weekly: ask a headless Claude what each new session should change in the rules.

Run by `.github/workflows/review-sessions.yml`. The rule skills learn only when
the user points something out (rules-feedback) or a repeatable task is noticed
mid-session (skill-create); this adds the third trigger over the session logs
committed under .claude/sessions/. Until 2026-10-17 the same prompt ran as the
SessionEnd hook `reflect-session.py`; it moved here because every session since
2026-10-04 ran in the cloud, where a proposal written at SessionEnd never
reached the repository.

It proposes and never applies. A proposal becomes a rule only when the user
adopts it, through rules-feedback and rules-editing. A session with nothing to
propose leaves no file; the ledger `.claude/rule-proposals/reviewed.txt` records
that it was read, so it is not read again.
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from session_log import ROOT, ask, meta, record, turns, unprocessed  # noqa: E402

OUT = ROOT / ".claude" / "rule-proposals"
LEDGER = OUT / "reviewed.txt"
MAX_CHARS = 300_000
NONE = "NONE"

PROMPT = """\
You review one finished Claude Code session in a repository whose AI operating
rules live as skills under .claude/skills/, slash commands included. Your job
is to find what this session should change in those rules, so the next
session behaves better without the user repeating themselves.

Propose something only when the conversation itself gives the evidence:
- the user corrected Claude, rejected an approach, or restated an instruction
  Claude had missed;
- the user stated a preference, constraint, or fact about their environment that
  should hold beyond this session;
- a multi-step procedure was worked out that is likely to recur and no existing
  skill or command covers it;
- an existing skill's text was wrong, contradicted what the user wanted, or was
  silent where the session needed it.

Do not propose anything that is only about this one task, anything already
covered by a skill in the roster, or anything general Claude already does well.
Prefer updating an existing skill over creating a new one. Never invent evidence.

If there is nothing worth proposing, reply with exactly the single word {none}
and nothing else.

Otherwise reply in Japanese, in Markdown, with one section per proposal:

## <一行の要約>

- 種別: 既存スキルの修正 | 新規スキル | 新規コマンド | その他
- 対象: <skill or command name, or file path>
- 根拠: <quote the user's words from the conversation, with its time>
- 提案: <what to add, change, or remove, concretely enough to apply as is>

<<<ROSTER>>>
{roster}
<<<END ROSTER>>>

<<<CONVERSATION>>>
{conversation}
<<<END CONVERSATION>>>
"""


def frontmatter(path):
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return ""
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    return m.group(1) if m else ""


def roster():
    """Skills and slash commands (`disable-model-invocation: true`) with their descriptions."""
    skills, commands = [], []
    for skill in sorted((ROOT / ".claude" / "skills").glob("*/SKILL.md")):
        head = frontmatter(skill)
        d = re.search(r"^description:\s*(.*(?:\n[ \t]+.*)*)", head, re.M)
        desc = " ".join(d.group(1).split()) if d else ""
        manual = bool(re.search(r"(?m)^disable-model-invocation:\s*true\s*$", head)) and not desc.startswith("Retired.")
        (commands if manual else skills).append(("- /" if manual else "- ") + f"{skill.parent.name}: {desc}")
    return "\n".join(["Skills:", *skills, "Commands:", *commands])


def main():
    logs = unprocessed(LEDGER)
    if not logs:
        print("reflect: nothing new")
        return 0
    names = roster()
    failed = 0
    for log in logs:
        text = log.read_text(encoding="utf-8")
        if not any(who == "User" for who, _ in turns(text)):
            record(LEDGER, log.name)
            print(f"reflect: {log.name}: no user turn")
            continue
        reply = ask(PROMPT.format(none=NONE, roster=names, conversation=text[-MAX_CHARS:]))
        if reply is None:
            failed += 1
            print(f"reflect: {log.name}: failed, left for the next run")
            continue
        record(LEDGER, log.name)
        if reply == NONE:
            print(f"reflect: {log.name}: nothing to propose")
            continue
        info = meta(text)
        header = [
            f"# ルール改善案: {log.stem}",
            "",
            f"- session_log: ../sessions/{log.name}",
            f"- session_id: {info['session_id']}",
            f"- started: {info['started'] or '-'}",
            "",
        ]
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / log.name).write_text("\n".join(header) + "\n" + reply + "\n", encoding="utf-8")
        print(f"reflect: {log.name}: proposal written")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
