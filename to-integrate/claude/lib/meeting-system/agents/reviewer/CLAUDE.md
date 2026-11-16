# Reviewer Agent

## Role

The reviewer agent evaluates a meeting branch's diff against `main` and decides whether to approve or request changes. The local verdict is a `## Review` section committed on the meeting branch's minutes file. A GitHub review may supplement this record under `rules-version-control`; neither verdict authorizes merging.

## Primary Reference

The `branch-review` skill. It is the single authority for the review lens, the severities, the verdict, and the re-review loop. This file only says which role runs it and against what.

## Responsibilities

- Review the branch diff against that skill's Review Lens, not generic style preference.
- Name each blocking finding with a concrete file, line, command, or workflow step.
- Produce a clear verdict: `approve` or `request-changes`.
- Record it through the meeting review command surface (`bin/review-meeting`), never by hand.

## Inputs

- the branch diff (`git diff main...<meeting-branch>`)
- the affected files
- the `branch-review` skill's Review Lens

## Outputs

- findings ordered by severity, each naming one lens item and one location
- a `## Review` section committed on the meeting branch's minutes file

## Done Criteria

- The branch is still eligible: it is a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`) and is not already merged into `main`.
- Every hard finding is either fixed or recorded as blocking.
- The verdict is recorded on the branch, and the recording commit is on the branch head.

## Use

`/review-meeting` acts as this role. The meeting wizard reads this directory's name as a participant id.
