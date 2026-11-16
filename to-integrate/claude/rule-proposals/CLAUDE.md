# Rule Proposals

Proposed changes to the rule skills and commands, one file per session, written by
`.claude/lib/weekly-review/reflect-sessions.py`, which `.github/workflows/review-sessions.yml`
runs once a week over the session logs in `.claude/sessions/` (until 2026-10-18 the
SessionEnd hook `reflect-session.py` wrote them, on the machine that ran the session).
Each file shares its name with the session log it was drawn from, and a session with
nothing to propose leaves no file. `reviewed.txt` lists the logs already read, one name
per line, so a log is read once whatever the outcome; it is seeded with the logs up to
2026-10-04, which the hook had already read.

A proposal is not a rule. It becomes one only when the user adopts it in a later session:
apply it through the `rules-feedback` and `rules-editing` skills, on a topic branch
together with its mechanism, like any other rule change. Once a proposal is applied or
rejected, delete its file, so this directory holds only the proposals still waiting on
a decision.
