# Agents

Subagent definitions Claude Code loads by name. Each file with agent frontmatter
is one agent: its frontmatter sets the name, the tools it may use, and the model,
and its body is the agent's instructions. This `CLAUDE.md` has no such frontmatter,
so it is not loaded as an agent.

| Agent | What it does | What runs it |
| --- | --- | --- |
| `review-commit.md` | Reviews a staged diff against the `branch-review` skill's lens and verdict, and returns `VERDICT: approve` or `VERDICT: request-changes` with findings | By hand, with a staged diff, its stat, the commit message and the branch; the git hook that ran it on every commit was retired on 2026-10-17 |

A staged diff can be reviewed with it before the commit is attempted.
