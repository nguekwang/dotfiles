# .claude/lib/weekly-review

The two scripts `.github/workflows/review-sessions.yml` runs once a week over the
session logs under `.claude/sessions/`, and the module they share. They replace
two SessionEnd hooks retired on 2026-10-17, `reflect-session.py` and
`grade-english.sh`, whose output never reached the repository once every session
ran in the cloud (#65, #64).

| File | Does | Writes |
| --- | --- | --- |
| `session_log.py` | Reads a session log (header, turns, the user's text), keeps a ledger of processed logs, runs `claude -p` and reports its failure instead of hiding it | nothing |
| `reflect-sessions.py` | Asks what each new session should change in the rule skills; proposes, never applies | `.claude/rule-proposals/<log name>` and the ledger `.claude/rule-proposals/reviewed.txt` |
| `grade-sessions.py` | Grades the foreign-language prose of the user's turns; Japanese is skipped | `silver-lake/polyglot/<lang>/log/<yyyy-mm-dd-HH:MM:SS>.md` and the ledger `silver-lake/polyglot/graded.txt` |

Each script takes the logs not in its ledger, oldest first, at most `LIMIT` of
them (environment variable, default 20), and records a log in the ledger once it
has been read, whatever the outcome, so a log is paid for once. A log whose call
failed is left out of the ledger and the script exits 1, so the run shows red and
the next run retries it. `ANTHROPIC_API_KEY` must be in the environment; the
model is `opus`, as the hooks used.

To run one by hand from the repository root, with the `claude` CLI on `PATH`:

```sh
LIMIT=1 python3 .claude/lib/weekly-review/reflect-sessions.py
```
