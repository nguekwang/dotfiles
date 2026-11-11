# Command Entry Points

Thin wrappers, each of which execs the matching script under `scripts/utils/`, so a meeting command can be put on `PATH` (see `docs/runbooks/meeting-command-path-setup.md`): `open-meeting`, `start-claude-meeting`, `list-meetings`, `clean-worktrees`, `review-meeting`, `approve-meeting`. Closing a meeting has no wrapper; integration runs git directly per the `rules-version-control` skill.
