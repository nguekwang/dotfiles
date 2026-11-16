#!/usr/bin/env python3
"""Print the skill roster as a Markdown table, read from frontmatter.

    python3 .claude/lib/list-rules/list-rules.py skills [keyword]

The `skills` argument is the only mode left; it stays so `/list-skill`'s existing
invocation does not change. `keyword` keeps only the skills whose name contains it (case-insensitive).
Read-only, standard library only. An entry with an empty description is
marked, because `description` is the whole routing signal.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SKILLS = ROOT / ".claude" / "skills"


def frontmatter(path: Path) -> dict:
    """The YAML frontmatter of a Markdown file, folded values joined."""
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return {}
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fields: dict = {}
    key = None
    for line in text[3:end].split("\n"):
        m = re.match(r"^([a-zA-Z_-]+):\s*(.*)$", line)
        if m:
            key = m.group(1)
            fields[key] = m.group(2).strip()
        elif key and line.strip():
            fields[key] = (fields[key] + " " + line.strip()).strip()
    for k, v in fields.items():
        value = re.sub(r"^[>|][+-]?\d*\s*", "", v.strip())
        fields[k] = re.sub(r"\s+", " ", value).strip()
    return fields


def rows(needle: str) -> list:
    out = []
    for path in sorted(SKILLS.glob("*/SKILL.md")):
        name = path.parent.name
        if needle in name.lower():
            out.append((name, frontmatter(path).get("description", "")))
    return out


def main(argv: list) -> int:
    if not argv or argv[0] != "skills":
        print(__doc__.strip().split("\n\n")[1], file=sys.stderr)
        return 2
    found = rows(" ".join(argv[1:]).strip().lower())
    print("| name | description |\n| --- | --- |")
    for name, description in found:
        cell = (description or "(EMPTY: does not route)").replace("|", "\\|")
        print(f"| {name.replace('|', chr(92) + '|')} | {cell} |")
    print(f"\n{len(found)} skills")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
