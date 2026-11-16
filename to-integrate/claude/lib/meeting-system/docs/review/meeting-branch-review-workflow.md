# Meeting Branch Review Workflow

The lens, the severities, the verdict, and the re-review loop all live in the
`branch-review` skill. What remains here is meeting-specific: the role wiring,
the order of the standard flow, and the conflict policy for a meeting branch
that went stale.

## Roles

- `integrator`: integrates the finished meeting branch into `main` through the selected, authorized path under `rules-version-control`
- `reviewer`: reviews the branch's diff against `main` against the `branch-review` skill's Review Lens, which is the single authority for the lens and the verdict
- `rv/approve`: records the approval when the reviewer verdict is approval
- `secretary`: fixes issues raised by the reviewer and returns the branch for re-review

The commands below record each verdict as a `## Review` section committed on
the meeting branch's minutes file. A pull request and GitHub review may
supplement this local record under `rules-version-control`; they do not replace
the required reviews or authorize merging. Meeting closure also does not
authorize merging; obtain explicit user authorization for the selected path.

## Standard Flow

1. Finalize the minutes and commit them on the meeting branch with a plain `git commit` (reviewed per the `rules-version-control` skill), without merging.
2. The reviewer agent evaluates the branch's diff (`git diff main...<meeting-branch>`) against the `branch-review` skill's Review Lens.
3. If the verdict is `approve`, record it with `bin/review-meeting <meeting-branch> --decision approve` (or `bin/approve-meeting <meeting-branch>`). The script's commit is reviewed like any other; when that review refuses it, the `## Review` section stays staged, and it is committed after the fix with exactly `git commit -m "Record review (approve) for <meeting-branch>"`, the subject the merge gate checks before a merge.
4. If the verdict is `request-changes`, record it with `bin/review-meeting <meeting-branch> --decision request-changes`.
5. The secretary agent applies the requested fixes on the same meeting branch.
6. The reviewer agent re-runs the lens and either approves or requests more changes.
7. Once review requirements pass and the user explicitly authorizes merging, integrate through the selected path under `rules-version-control`. Direct integration uses `git merge --no-ff`; otherwise follow the authorized pull-request workflow.

## Operational Rule

- `review-meeting-branch.sh` should only act on meeting branches that are not yet merged into the base branch.
- The reviewer agent should not approve if any hard requirement in the review lens fails.
- The secretary agent should not broaden scope beyond the review findings unless the user asks for it.
- Do not integrate a branch whose most recent recorded review verdict is `request-changes`.

## Conflict Resolution Policy

Meeting branches diverge from `main` when other meeting branches merge first, so
a branch can go stale before it is integrated. Resolve such conflicts with
`main` treated as the source of truth and the branch contributing only its own
intent on top.

### Principles

1. **Re-sync before resolving.** Merge the latest `main` into the meeting
   branch (or rebase it) and resolve from there. Never hand-edit a diff that
   was computed against a stale base.
2. **Minutes files (`docs/minutes/*.md`) `add/add` conflicts default to `main`.**
   If the same meeting already landed on `main` independently, drop that file
   from the branch. Keep only minutes that are genuinely new to this branch.
3. **Shared scripts (`scripts/utils/*.sh`) are rebased on `main`'s structure.**
   Do not merge line-by-line. Take `main`'s current shape and re-apply only the
   branch's behavioral intent (the feature), discarding helper blocks that
   already exist on `main`.
4. **Land with an authorized merge commit.** After resolving and completing
   the required reviews, obtain explicit user authorization for integration.
   Direct integration uses `git merge --no-ff`; a pull-request path follows
   `rules-version-control`. Never squash, fast-forward, or force-push.
5. **Prevent staleness.** Land meeting branches promptly. If a branch must
   stay open, periodically merge `main` into it so conflicts stay small.

### Triage for a superseded branch

When most of a branch's content has already merged to `main` through other
meetings, do not fight a large conflict. Instead, cherry-pick only the
branch's net-new files onto a fresh branch cut from `main`, integrate that,
and drop the original branch as superseded.
