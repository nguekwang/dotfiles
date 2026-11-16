# Git Hooks

Hooks that git itself runs, as opposed to the Claude Code hooks one level up.
git does not read this directory directly. `install-hooks.sh`, run by the first
SessionStart hook at every session start and by hand after a commit changes a
hook mid-session, writes each hook as it is in `HEAD` to the clone's shared hooks
directory (`<git common dir>/hooks/`) under git's fixed name and leaves
`core.hooksPath` unset, so every branch and worktree runs the same copy. Only the
installed copies carry git's hook names; the files here are named for what they do.

| File | Installed as | Role |
| --- | --- | --- |
| `install-hooks.sh` | n/a | Installs the hook below for this clone, and removes the copies of the retired `commit-msg`, `pre-push` and `reference-transaction` hooks an earlier run installed, recognised by their header; run again after a commit changes it |
| `guard-pre-rebase` | `pre-rebase` | Refuses every rebase, per the `rules-version-control` skill's "Never Rewrite History" |

Until 2026-10-17 this directory also held the per-commit review (`review-commit-msg`
and its launcher `dispatch-commit-msg`, installed as `commit-msg`) and two guards
of `main` (`guard-main-ref` as `reference-transaction`, `guard-main-push` as
`pre-push`). The user retired them; review moves to the pull request and the
protection of `main` to GitHub's branch protection (#31).

A hook here must be executable and must fail closed: when it cannot do its job,
it refuses the operation instead of letting it through.
