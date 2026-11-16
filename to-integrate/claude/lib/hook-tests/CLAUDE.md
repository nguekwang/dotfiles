# Hook Tests

One test script per hook under `.claude/hooks/` that has one, named
`test-<hook name>.py`. Each script runs with `python3` alone, builds whatever
fixtures it needs in a temporary directory, never calls the network or a model,
prints one line per case, and exits non-zero when any case fails.

| Script | Hook | What it covers |
| --- | --- | --- |
| `test-guard-git.py` | `guard-git.py` | That a new branch name is rewritten to the permitted form and a conforming or existing name is left alone, that `git worktree remove --force` is warned about and a plain removal is not, and that `gh` commands and topic pushes pass untouched. All commands are inspected as fixture strings, never executed. |

The tests of the hooks retired on 2026-10-17 left with them; git history holds
them.

Run a hook's test after every change to that hook, and state the result in the
branch record under `.claude/log/`.
