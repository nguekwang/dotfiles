# .github/workflows

GitHub Actions that run checks, per the `rules-version-control` skill, "Pull
Requests and Hosting Tools": they enforce the templates and are not a system of
record. `enforce-templates.yml` closes an issue that lacks the title form or the
`Why` / `What` / `Done when` headings, and fails a PR check whose body lacks
`Closes #<n>` or `No issue: <reason>`, `Why`, `Changes`, `Verification`.
`review-pull-request.yml` has the Claude Code GitHub Action review every
non-draft pull request against the `branch-review` skill's lens and post one
sticky comment; it is the successor of the retired per-commit review (#63) and
pairs with the branch protection of `main` (#31). `review-sessions.yml` runs
the two scripts of `.claude/lib/weekly-review/` every Sunday 21:17 UTC (Monday
06:17 JST), or on `workflow_dispatch`, and opens a pull request with the rule
proposals and grades they wrote (#64, #65). Pin every action to a commit SHA.

Both need the repository secret `ANTHROPIC_API_KEY`; without it the review is
skipped with a notice and the weekly run fails at its first step. The weekly
run also needs "Allow GitHub Actions to create and approve pull requests" on
under Settings, Actions, General, or `gh pr create` is refused. Weekly, not
daily, because Actions minutes on a private repository are metered.
