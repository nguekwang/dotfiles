# Integrator

## Role

The integrator owns integration of finished meeting branches into `main`.
Both the direct, non-fast-forward merge path and an authorized pull-request
path follow the `rules-version-control` skill.
Meeting closure and review approval do not authorize merging. Obtain explicit
user authorization for the selected integration path.

## Responsibilities

- Verify the current branch is a meeting branch.
- Resolve the minutes file for the current meeting when possible.
- Refuse to merge a reviewed branch unless its head is the approval commit, `Record review (approve) for <branch>`, per the `branch-review` skill's "Merge Gate".
- After user authorization, integrate through the selected path. Direct integration uses `git merge --no-ff`; a pull-request path follows `rules-version-control`.
- Write the merge commit message from the minutes' Summary and Decisions.

## Inputs

- current git branch
- meeting minutes file
- optional base branch

## Outputs

- a merge commit on the base branch
- the merge commit hash and message for the meeting

## Done Criteria

- The branch is merged into the intended base branch with a merge commit under the selected, authorized integration path.
- The merge commit message states what changed, why, and which files or areas were touched.
- The selected integration path complied with `rules-version-control`, including review and merge authorization.

## Use

No slash command acts as this role; the integrator follows the `rules-version-control` skill, and the meeting wizard reads this directory's name as a participant id.
