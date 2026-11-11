---
name: branch-review
description: >-
  Reviewing a local topic branch, meeting branches included: reading its diff
  against the integration branch, judging it against one fixed review lens,
  recording the verdict on the branch itself, driving the fix-and-re-review
  loop, and gating the merge on the latest verdict. Pull requests may supplement
  the durable Git-native review record. Use whenever the user asks for a code
  review, asks whether a branch is ready to merge, hands a branch over for
  review or approval, or runs /review-meeting, /approve-meeting, or /apply-review-findings.
---

# Branch Review

Review every topic branch as a diff against the integration branch, judge it against the lens below, and record the verdict on the branch itself. A pull request may carry the review discussion and give the user a reviewable link; the committed verdict and merge gate remain required by this skill and `rules-version-control`. Review approval is not permission to merge: obtain explicit user confirmation before integration.

This skill is the single authority for the lens and the verdict. It covers both a plain topic branch and a meeting branch: the only difference between them is where the record file sits, and the Record Location section below states it. A meeting branch used to be reviewed against a second, separate lens under `meeting-system`; two fixed lenses cannot both be fixed, so that one was folded into this one and its items appear here.

The axis of this skill is the review lifecycle: where the record lives, who acts, what the reviewer reads, what the reviewer judges, how a finding is graded, how the verdict is written down, how a rejected branch comes back, and how the merge is gated. Each section below is one stage, in that order.

## Record Location

Axis: where the durable verdict lives. A hosted discussion may supplement the committed record.

- Hosted pull request: allowed for discussion, review, and user visibility. Preserve the final verdict in the committed record below so the merge gate remains portable.
- Conversation only: rejected. A verdict that lives in a chat transcript is not reachable from the repository, so the merge cannot be gated on it and a later reader cannot find it.
- Committed file on the branch: chosen. The record travels with the branch, lands on the integration branch inside the same merge, and the merge commit message cites it.

Which file depends on whether the branch already has a durable artifact of its own.

| Branch | Record | Why |
| --- | --- | --- |
| a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`) with a minutes file | a `## Review` section appended to that minutes file | The minutes file is already the meeting's record; a second file would split it |
| Any other topic branch | `.claude/reviews/<yyyymmddhhmmss>-<branch-slug>.md` | The branch has no durable artifact, so the review creates one |

The timestamp is taken at the first round per the `files-and-repository` skill, and later rounds append to the same file. The slug is the branch name lowercased with every run of characters outside `[a-z0-9]` replaced by one `-`. The `record` subcommand creates the directory and its `CLAUDE.md` on first use.

## Roles

Axis: who acts. Four roles, and the first two are never the same context.

- Author: produced the branch. Hands it over per the `review-handoff` skill: what changed since the last review, structured MECE, and what was run to verify it.
- Reviewer: a context that did not write the diff. In order of preference: the user reading the diff locally, a separate agent session, or a subagent spawned with nothing but the `show` output and this skill. A session reviewing its own diff inherits its own blind spots, which is the defect this separation prevents.
- Secretary: converts a `request-changes` verdict back into edits on the same branch, then returns it for re-review. Applies the minimum set of changes the findings call for and no more; broadening scope past the findings needs the user to ask for it.
- Recorder: the script under `scripts/`, or `meeting-system/bin/review-meeting` for a meeting branch. It validates eligibility, writes the record, and commits it, so every record has one shape regardless of who reviewed.

## Inputs

The reviewer reads exactly what `show` prints, and nothing the author says in place of it.

```sh
bash .claude/skills/branch-review/scripts/branch-review.sh show <branch> [--base <branch>]
```

It refuses a branch that does not exist or is already merged into the base, then prints the commit list, the file stat, and the full three-dot diff (`base...branch`). The base defaults to `main`; pass `--base` only when the integration branch differs, resolved as the `rules-version-control` skill describes.

Eligibility is part of the input, not a courtesy check: a branch that does not exist, or that is already merged into the base, has nothing left to review, and recording a verdict on it would attach a decision to history that already landed.

## Review Lens

Axis: the property of the change under judgement. Every finding names exactly one item, and a change passes when no item yields a blocking finding.

1. Intent. The diff implements the whole request and nothing beside it. Partial coverage and silent scope growth are both defects, and end-to-end completion outranks partial analysis: if the request implies follow-through such as integrating the branch or cleaning it up, the work carries through unless something blocks it.
2. Correctness. The change behaves as specified on normal and edge inputs, handles its error paths, and regresses nothing the diff touches.
3. Safety. No destructive or irreversible action runs without a guard, no secret enters history, and no rule of the `rules-version-control` skill is broken (rewritten history, an unauthorized push, a retired branch). Automation that integrates or records must verify eligibility before acting, and no process step may depend on someone remembering it.
4. Explicitness. Decisions, defaults, and exceptions are written down rather than left implied. Operator-facing commands and their required inputs are unambiguous, and an assumption the change rests on is stated instead of buried in prose.
5. Traceability. A reader can point from the request to the files, commands, or workflow steps that implement it, and each finding names a specific gap rather than generic dissatisfaction. Automation is grounded in a documented path, not an undocumented side route.
6. Conformance. Names follow the `files-and-repository` skill, language follows the `language-selection` skill, prose follows the `prose-style` skill, tables follow the `figure-rendering` skill, and commit messages follow the `rules-version-control` skill. A durable internal artifact is in English unless a stronger policy says otherwise, and it records final outcomes rather than conversational noise.
7. Simplicity. The change is the minimal one that satisfies intent: one standard path for the common case, an exception only where the edge case is real and named, no speculative abstraction, no duplicate of an existing script or rule, no dead path.
8. Evidence. Every claim in the handoff is observed or derived per the `logical-thinking` skill, and the author states what was run to verify the change.
9. Other. A finding that fits none of the above. Name why it fits none, so the lens is extended per the `rules-feedback` skill instead of the residual growing silently.

The justification is reviewability: a fixed lens makes two reviewers of the same diff reach the same verdict, and makes a request for changes actionable, because each finding points at one named property instead of at taste. The standard the lens serves is one sentence: approve only what is operationally useful, technically defensible, and actionable without follow-up clarification.

## Severity and Verdict

Axis: the consequence of merging with the finding unfixed.

- blocking: merging would break intent, correctness, safety, or explicitness. Fixed before approval, without exception.
- should-fix: merging would leave a traceability, conformance, simplicity, or evidence gap the author can close in the same branch. Fixed, or parked with a stated reason, before approval.
- nit: cosmetic. Recorded, never a reason to withhold approval.

The verdict is `approve` when zero blocking findings remain and every should-fix is fixed or parked with a reason; otherwise `request-changes`. Prioritise bugs, regressions, workflow ambiguity, and missing guardrails over style. Order findings by severity, and write each as one line:

```text
- [blocking] path/to/file:42 - correctness - <what is wrong> - <what to change>
```

A finding that names no file, line, command, or workflow step is under-specified; rewrite it until the author can act on it without asking.

The reviewer's output is the verdict, the findings ordered by severity, the concrete fix each one calls for, and, when the verdict is `request-changes`, the condition under which the branch comes back.

## Recording

Write the findings to a file, then let the recorder commit them on the branch.

```sh
bash .claude/skills/branch-review/scripts/branch-review.sh record <branch> --decision <approve|request-changes> --findings <file> [--base <branch>] [--reviewer <name>]
```

The recorder requires a clean working tree, switches to the branch, appends a `## Round n` section holding the decision, the timestamp, the reviewer, the reviewed head commit, and the findings verbatim, commits it as `Record review round n (<decision>) for <branch>`, and switches back.

That commit goes through the commit review of the `rules-version-control` skill's "Review Every Commit" like any other, so run `record` with a 600,000 ms tool timeout. When the review refuses the record commit, the recorder exits non-zero and leaves the checkout on the reviewed branch with the record staged there, naming the branch to return to: fix what the commit review names, commit the staged record with `git commit` on that branch, then switch back.

A meeting branch records through `meeting-system` instead, which appends the same decision as a `## Review` section on the minutes file: `.claude/lib/meeting-system/bin/review-meeting <branch> --decision <approve|request-changes>`, or `bin/approve-meeting <branch>` for the approval case. The lens and the verdict definitions are the ones above either way; only the file differs.

## Re-Review Loop

A `request-changes` round is followed by the secretary's fixes on the same branch and a new round. There is no round limit, and each round appends rather than replacing, so the branch carries the whole history of what was asked and what was done.

The secretary turns each finding into one concrete edit task, applies the minimum set that satisfies the lens, preserves the author's intent and the existing workflow conventions, and hands back a short summary of what changed. The reviewer then re-runs the lens against the new diff.

A meeting branch that has gone stale against a `main` that moved is re-synced before the next round rather than reviewed against a stale base; the conflict policy for that case is in `meeting-system/docs/review/meeting-branch-review-workflow.md`.

## Merge Gate

Before integrating a reviewed branch per the `rules-version-control` skill, read the latest verdict.

```sh
bash .claude/skills/branch-review/scripts/branch-review.sh verdict <branch> [--base <branch>]
```

Exit 0 means the latest round is `approve` and the branch head is still that round's record commit, so the merge may proceed. Exit 1 means `request-changes`, or a head that moved after approval, so it may not. Exit 2 means no record exists. Cite the record file and the round in the merge commit message. A branch nobody asked to review carries no record and integrates as the `rules-version-control` skill already describes; this skill gates a branch only once a review was requested.

For a meeting branch, the same gate applies: once a review is recorded, integrate only when the branch head is the approval commit `review-meeting-branch.sh` made, `Record review (approve) for <branch>`, so a `request-changes` verdict or any commit after the approval stops the merge. Check it with `git log -1 --format=%s <branch>`: merge only when it prints exactly `Record review (approve) for <branch>`, and otherwise stop and say what it printed.

## Verification

Before reporting a review as done, verify: `show` was the reviewer's input, every finding names one lens item and one location, the severities and the verdict agree with the definitions above, the recorder committed a round on the branch, and `verdict` returns the exit code the verdict implies.
