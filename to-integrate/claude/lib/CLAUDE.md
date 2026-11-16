# .claude/lib

Assets that commands and skills read, or that the user runs directly, and that the CLI must not scan.

Claude Code scans exactly four directories under `.claude`: `commands`, `agents`,
`output-styles`, and `skills`. Anything placed in one of them is registered as an
artifact of that kind, whether or not it was meant to be. Two things here were in
the wrong place because of that:

- `mtg-system` (now `meeting-system`) sat under `skills/`, where it was registered as a rule skill even
  though its own description said it is never invoked directly. It is a library:
  scripts, protocol docs, and role docs that the `mtg`, `rv-*`, `secretary`, and
  AI-Org commands (now the meeting commands such as `/open-meeting`) read and run. Its `SKILL.md` is now `CLAUDE.md`, per this
  repository's directory-index convention.
  was registered as a slash command of its own
  reference file has no frontmatter). The command, now the skill `audit-work-log`, sits
  under `skills/`; only the material it reads moved here.

| Directory | Read by | Holds |
| --- | --- | --- |
| `meeting-system/` | `/open-meeting` `/clean-worktrees` `/list-meetings` `/review-meeting` `/approve-meeting` `/apply-review-findings` `/research-strategy` `/estimate-impact` `/write-proposal-narrative` `/normalize-proposal-feedback` `/build-proposal` | `bin/`, `scripts/`, `docs/` (minutes, review, runbooks), `agents/` role docs, the AI-Org organization model |
| `audit-work-log/` | `/audit-work-log` | `references/input-formats.md`, `scripts/find-gaps.py` |
| `list-rules/` | `/list-skill` | `list-rules.py`, a standard-library script that prints the skill roster (slash commands included) from frontmatter |
| `weekly-review/` | `.github/workflows/review-sessions.yml`, weekly | `reflect-sessions.py` (rule proposals), `grade-sessions.py` (foreign-language grades) and the module `session_log.py` they share |
| `hook-tests/` | whoever changes a hook under `.claude/hooks/`, and that hook's docstring | one test script per hook that has one, runnable with `python3` and no network |
| `tools/` | the user, directly (no skill, command or hook calls them) | standalone personal scripts: `parse-cashflow/` (Rakuten Bank CSV to cash-flow JSON), `drive-qutebrowser/` (qutebrowser control) |

`agents/` under `meeting-system` is ordinary content, not subagent definitions: the
CLI reads subagents only from `.claude/agents/`.

Put a new asset here when a command or skill needs to read it, or the user runs it directly, and it is not
itself a rule. A rule belongs in `skills/`, per the `rules-structure` skill.
