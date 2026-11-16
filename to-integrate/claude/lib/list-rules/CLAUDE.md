# list-rules

The script `/list-skill` runs. Nothing here runs on its own.

`list-rules.py` reads the frontmatter of `.claude/skills/*/SKILL.md` (the slash commands are skills too) and prints a Markdown table of name and description. It is read-only and uses only the standard library.

    python3 .claude/lib/list-rules/list-rules.py skills [keyword]

An entry with an empty `description` is marked `(EMPTY: does not route)`.
