---
name: list-skill
description: List all skills under .claude/skills/, with each one's description
disable-model-invocation: true
---

# /list-skill

Run `python3 .claude/lib/list-rules/list-rules.py skills $ARGUMENTS` and
present its table as it is, each description verbatim.

Do not glob the directory and parse frontmatter by hand. The script already
reads every `SKILL.md` and folds each `description` onto one line; doing it again
in the conversation costs a turn and risks a different answer.

Report any skill the script marks `(EMPTY: does not route)`: `description` is the
whole routing signal, so that skill never routes.

Usage: `/list-skill [keyword]`

Target keyword (optional; filters to skills whose name contains it): $ARGUMENTS
