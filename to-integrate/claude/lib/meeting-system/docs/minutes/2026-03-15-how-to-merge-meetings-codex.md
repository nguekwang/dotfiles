---
title: how-to-merge-meetings
meeting_name: how-to-merge-meetings
topic: how-to-merge-meetings
date: 2026-03-15
timestamp: 2026-03-15T14:38:33+09:00
tool: Codex
meeting_type: general
participants: all
objective: Decide how to merge meeting branches
constraints: None
started_from_branch: main
branch: mtg/2026-03-15-how-to-merge-meetings
status: final
---

# Meeting: how-to-merge-meetings

## Agenda

- Decide the default merge strategy for `mtg/*` branches
- Preserve traceability for meeting minutes and related meeting work
- Minimize history noise and operator ambiguity in the normal flow

## Current Focus

- Finalize the merge-policy and meeting-review workflow changes into durable repository process

## Summary

The repository already standardizes meeting work onto `mtg/<date>-<topic>` branches and expects a PR back to `main`, but it does not yet define how those PRs should be merged. The core tradeoff is between preserving full branch history and keeping `main` readable.

The leading recommendation is to make `squash merge` the default for meeting branches. That keeps `main` concise while preserving the final minutes file, the PR discussion, and a single commit that represents the meeting outcome. A regular merge commit should remain available only when a meeting branch intentionally contains multiple independently meaningful commits that need to stay visible on `main`.

During this meeting, the live PR queue was checked and only one open PR existed: `#8 docs(minutes): enable-agents`. GitHub reported it as clean, so it was squash-merged successfully into `main` with merge commit `41c48c7c55158a5401bea8434269c08b5057432c`, and the queue is now empty.

The meeting then expanded into implementation: the repository now has an explicit `mtg` agent for opening meeting PRs and an `rv/approve` agent for approving eligible meeting PRs. Thin wrappers were added so the workflow can be executed with dedicated commands instead of ad hoc `gh` calls.

The meeting then expanded again into a full review loop. A durable user review lens was documented, a reviewer agent and generic review command were added so meeting PRs can be approved or sent back with requested changes, and a secretary agent was defined to implement fixes before re-review.

Late in the meeting, a documentation consistency gap was identified: durable document references were still using absolute local filesystem paths in several places, despite the intended policy being to use GitHub URLs. The meeting docs and templates were updated so durable references now point to GitHub blob URLs instead of local paths.

The repository state was also checked for parallel worktrees. As of 2026-03-15, there was only a single active worktree for this repository.

## Context

This meeting was started specifically to decide how meeting branches should be merged after the repository's meeting workflow was formalized. Existing documentation and scripts already cover branch creation, minutes finalization, `git push --set-upstream`, issue creation, and PR opening, but they stop short of specifying whether the resulting PR should be squash-merged, rebased, or merged with a merge commit.

Because meeting branches are process artifacts rather than long-lived feature branches, the merge decision should optimize for durable minutes, low ambiguity, and a clean default that humans and AI tools can apply repeatedly.

## Discussion

### User

- Requested a decision on how meeting branches should be merged.
- Set the meeting format to role-based discussion with running notes and final decisions, open questions, and action items.
- Instructed that all currently open PRs should be merged immediately and that any conflicts should be resolved so the latest state is reflected.
- Requested an agent that can create `mtg` PRs and another agent that can review/approve them.
- Requested that the user's review perspective be documented and used by a reviewer agent to approve or reject PRs.
- Requested a secretary agent that fixes rejected PRs and returns them for re-review.
- Flagged that embedded document references should use GitHub URLs rather than local filesystem paths.
- Asked whether any parallel worktrees currently existed.

### PM

- The merge policy should be simple enough to apply every time without a separate judgment call.
- The main branch should reflect durable outcomes, not every intermediate note-taking step from a meeting session.
- The policy should align with the existing PR-based workflow rather than introducing a parallel path.
- Agent responsibilities should map cleanly onto the existing meeting close-out flow instead of duplicating it.
- The review loop should separate judgment from execution: reviewer decides, secretary fixes, and approval recording follows the reviewer verdict.

### Dev

- A meeting branch often contains minutes edits, small process changes, and follow-up automation in a short sequence; preserving every intermediate commit on `main` adds noise with limited value.
- `Squash merge` produces one coherent changeset for the meeting outcome and avoids exposing temporary WIP commit structure.
- `Rebase and merge` only works well if the meeting branch history is already intentionally curated, which is unlikely to be true for most meetings.
- A regular merge commit preserves exact branch topology, but that is probably more history than the workflow needs by default.
- The live repository state showed a single open PR, `#8`, with `mergeStateStatus=CLEAN`, so no manual conflict resolution was required before merge.
- Added `agents/mtg/README.md` to define the meeting PR creation role.
- Added `agents/rv/approve/README.md` to define the PR approval role for meeting branches.
- Added `scripts/utils/create_meeting_pr.sh` and `bin/mtg-pr` to open a PR from the current `mtg/*` branch by resolving the relevant minutes file.
- Added `scripts/utils/approve_meeting_pr.sh` and `bin/mtg-approve` to approve only eligible open PRs whose head branch matches `mtg/*`.
- Updated meeting docs so these commands are part of the standard workflow.
- Added `docs/review/user-review-lens.md` as the durable review standard inferred from the repository's existing operating preferences.
- Added `docs/review/meeting-pr-review-workflow.md` to document the `mtg -> reviewer -> rv/approve -> secretary -> re-review` flow.
- Added `agents/reviewer/README.md` for substantive review against the user review lens.
- Added `agents/secretary/README.md` for revision work after rejection.
- Added `scripts/utils/review_meeting_pr.sh` and `bin/mtg-review` so a reviewer can record either `approve` or `request-changes` on an eligible meeting PR.
- Converted `approve_meeting_pr.sh` into a compatibility wrapper around the new generic review command.
- Updated meeting docs, review docs, agent docs, and today's minutes so durable references use GitHub URLs rather than absolute local paths.
- Verified with `git worktree list --porcelain` that there is only one active worktree and no parallel worktree checkout.

### Ops

- The safest default is the one with the lowest operator ambiguity.
- A single merge mode should be documented as the default in the meeting workflow so humans and AI tools do not make inconsistent choices.
- If the repository later wants stronger enforcement, squash-only behavior is easier to validate in branch protection and review habits.
- Operationally, checking the live PR queue first avoided stale assumptions about how many meeting branches were actually pending.
- The approval script now performs eligibility checks before submitting approval, reducing accidental approvals on non-meeting PRs.
- The review command now centralizes both approval and request-changes behavior behind the same `mtg/*` eligibility guardrails.
- Standardizing durable references on GitHub URLs reduces environment-specific ambiguity when minutes are reviewed outside the local machine.

### Reviewer

- The repository currently has a process gap, not an implementation gap: the workflow explains how to open the PR but not how to land it.
- Defaulting to full merge commits for meeting branches would preserve detail that is rarely operationally important and would make `main` harder to scan.
- Defaulting to rebase would imply a level of commit curation that the current meeting workflow does not require.
- The most defensible default is squash merge, with an explicit exception path when preserving commit boundaries is materially useful.
- A review agent should not approve based on generic taste. It should apply a stable, documented lens tied to user intent, explicitness, traceability, simplicity, and operational safety.
- A rejection path is only useful if another role owns the fix. The new secretary role closes that loop.

## Review

- CEO perspective:
- A clear default matters more than theoretical flexibility because meeting branches are a recurring process path.
- World-class engineering perspective:
- Standardize on the merge mode that best matches the branch's purpose. For a meeting branch, the durable artifact is usually the final result, not the intermediate commit graph.
- Elite strategy consulting perspective:
- Use one default for the common case and define a narrow exception rule for unusual cases. That lowers coordination cost without blocking edge cases.
- Verdict: approved-with-conditions
- Conditions:
- The policy should explicitly define the exception path so reviewers know when not to squash.

## Decision Candidates

- Default to `Squash and merge` for PRs from `mtg/*` branches into `main`.
- Allow a normal merge commit only when the branch contains multiple distinct commits that should remain individually visible on `main`.
- Do not use `Rebase and merge` as the standard path for meeting branches.
- Use dedicated meeting agents and wrappers for PR creation and PR approval rather than relying on undocumented manual `gh` invocations.
- Use a documented user review lens as the basis for reviewer approval or rejection.
- Use a secretary agent as the default revision owner when a meeting PR receives requested changes.

## Decisions

- The currently open PR queue was processed during the meeting.
- PR `#8 docs(minutes): enable-agents` was squash-merged into `main`.
- No additional open PRs remained after verification.
- The repository now includes an explicit `mtg` agent for creating meeting PRs.
- The repository now includes an explicit `rv/approve` agent for approving eligible meeting PRs.
- The repository now includes a durable user review lens document for meeting-driven review decisions.
- The repository now includes a reviewer agent that can record either approval or requested changes on eligible meeting PRs.
- The repository now includes a secretary agent that owns revisions after reviewer rejection.
- Durable document references should use GitHub URLs rather than absolute local filesystem paths.
- There were no parallel worktrees active at the time of verification.
- The default merge recommendation for `mtg/*` branches is squash merge, while the exact exception rule for non-squash cases remains open.

## Open Questions

- Should the repository merely document squash-merge as the default, or also enforce it through GitHub repository settings or branch protection?
- What exact exception rule should justify using a non-squash merge for an `mtg/*` branch?
- Should the reviewer agent additionally require mergeability and green CI before approval, or is the user review lens sufficient for now?
- Should the secretary agent be limited to meeting minutes and workflow docs, or also be allowed to modify implementation files when the rejection findings require it?
- Whether older historical minutes and docs that still embed local filesystem paths should be migrated to GitHub URLs in a bulk cleanup.

## Parking Lot

- Whether non-meeting feature branches should follow the same merge policy
- Whether PR titles and squash commit messages for meetings should be standardized further
- Repository-wide cleanup of older local-path references outside the current meeting scope

## Action Items

- Owner: Codex
- Task: Update the meeting minutes with the chosen merge policy and patch the meeting workflow docs/scripts to reflect the new PR creation, review, and secretary agents.
- Deliverable: committed minutes and workflow updates on the meeting branch
- Due: completed in this meeting

- Owner: User
- Task: Confirm whether the default should be squash-only or whether merge commits should remain a documented exception path.
- Deliverable: explicit repository policy for exceptions to squash merge on `mtg/*` branches
- Due: TBD

- Owner: User
- Task: Confirm whether the first draft of the user review lens should be tightened further before it becomes the reviewer agent's strict gate.
- Deliverable: updated approval criteria in `docs/review/user-review-lens.md`
- Due: TBD

- Owner: Codex
- Task: Keep new durable document references on GitHub URLs and avoid adding new local filesystem links in meeting-facing docs.
- Deliverable: no new local filesystem links in meeting-facing durable docs
- Due: ongoing

## References

- [docs/minutes/MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [docs/minutes/README.md](README.md)
- [docs/review/user-review-lens.md](../review/user-review-lens.md)
- docs/review/meeting-pr-review-workflow.md
- [agents/mtg/README.md](README.md)
- [agents/reviewer/README.md](README.md)
- [agents/rv/approve/README.md](README.md)
- [agents/secretary/README.md](README.md)
- scripts/utils/create_meeting_pr.sh
- scripts/utils/review_meeting_pr.sh
- scripts/utils/approve_meeting_pr.sh
- bin/mtg-pr
- [bin/mtg-review](../../bin/mtg-review)
- [bin/mtg-approve](../../bin/mtg-approve)
- scripts/utils/open_meeting_pr.sh
- [scripts/utils/finalize-meeting.sh](../../scripts/utils/finalize-meeting.sh)

The unlinked entries above are the pull-request-based tooling this meeting
produced. It has since been replaced by the direct-merge tooling described in
[meeting-branch-review-workflow.md](../review/meeting-branch-review-workflow.md).
