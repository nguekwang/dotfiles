# Agent Roles

One directory per role in the meeting and AI-Org model, each with a `CLAUDE.md` stating the role. The meeting wizard (`scripts/utils/start-meeting.sh`) lists these directories as participant ids. A directory is a role exactly when its `CLAUDE.md` has a `## Role` heading, so container directories such as `marketing/` and `rv/` must not have one. A slash command acting as a role reads that role's `CLAUDE.md`.

| Directory | Role | Command that acts as it |
| --- | --- | --- |
| `integrator/` | Merges a finished meeting branch into `main` | none (follows `rules-version-control`) |
| `reviewer/` | Judges a meeting branch against the review lens | `/review-meeting` |
| `rv/approve/` | Records an approval | `/approve-meeting` |
| `secretary/` | Applies review findings | `/apply-review-findings` |
| `research/` | Source-backed market intelligence | `/research-strategy` |
| `marketing/analytics/` | Impact assumptions for strategy ideas | `/estimate-impact` |
| `reporting/` | Executive narrative and slide structure | `/write-proposal-narrative` |
| `dev/` | Turns proposal feedback into generation rules | `/normalize-proposal-feedback` |
