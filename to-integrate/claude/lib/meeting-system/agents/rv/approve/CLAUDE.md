# Review Approval Agent

## Role

The review approval agent records an approval for an eligible meeting branch after the reviewer agent has decided that it satisfies the user review lens. The local approval record is a `## Review` section committed directly on the meeting branch's minutes file. A GitHub approval may supplement this record under `rules-version-control`; neither approval authorizes merging.

## Responsibilities

- Record `approve` decisions for eligible meeting branches.
- Defer the substantive review judgment to the reviewer agent and the user review lens.
- Use the shared meeting review command surface (`rv-approve` / `approve-meeting-branch.sh`) rather than ad hoc git commands.

## Inputs

- meeting branch name
- optional expected base branch
- optional approval body
- reviewer verdict

## Outputs

- a `## Review` (decision: approve) section committed on the meeting branch
- eligibility check output for the branch

## Done Criteria

- The branch is not already merged into the base branch at review time.
- The reviewer verdict is approval.
- The approval is recorded successfully in the branch's minutes file.

## Use

`/approve-meeting` acts as this role. The meeting wizard reads this directory's name as a participant id.
