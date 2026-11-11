# Meeting Protocol

This document defines the minimal protocol for treating CLI-based AI interactions as structured meetings.

## Goals

- Separate casual discussion from actual decisions
- Convert AI conversations into reusable meeting minutes
- Update notes during the meeting and converge on a final version at the end
- Keep the format easy to save and automate

## Core Rules

1. The user declares the meeting name, meeting type, and purpose at the start.
2. The meeting starts on a meeting branch, `yyyy-mm-dd-hh-mm-discuss_<topic>`.
3. The AI speaks in roles and updates running notes during the meeting.
4. Off-topic discussions go to the `Parking Lot`, then return to the main thread.
5. Every meeting must end with `Decisions` and `Action Items`.
6. The saved artifact is the final minutes, not the full raw conversation.
7. Once `Action Items` are confirmed, keep them recorded as plain bullets in the minutes. Integration follows the direct-merge or pull-request path in the `rules-version-control` skill; durable meeting records remain Markdown files in the repository.
8. If the user says the meeting is over, ending, done, or equivalent, finalize the minutes and prepare the branch for integration. Meeting closure and review approval do not authorize merging; obtain explicit user authorization for the selected integration path.

## Start Format

At minimum, provide:

- Meeting Name
- Meeting Type
- Purpose
- Background
- Constraints
- Desired decisions

Example:

```text
Meeting Name: naming-policy
Meeting Type: general
Purpose: Decide the policy for managing naming conventions through IaC
Background: Naming differs across Terraform modules
Constraints: Must support both Azure and AWS
Desired Decisions: Naming elements, generation method, validation method
```

Use [meeting-start-prompt.md](meeting-start-prompt.md) as the kickoff template.

## AI Speaking Rules

The AI may speak from one or more of these roles, or close equivalents:

- `PM`: prioritization, scope, expected outcomes
- `Dev`: implementation approach, design, complexity, maintainability
- `Ops`: operational reliability, monitoring, continuous improvement, exception handling
- `Reviewer`: risks, omissions, alternatives

Only use the roles that matter. Every turn does not need every role.

## Running Note Update Rules

- The AI updates the minutes draft as needed each round.
- It does not need to repeat the entire draft every time; section diffs are enough.
- At minimum, keep `Summary`, `Discussion`, `Decision Candidates`, `Open Questions`, and `Action Item Candidates` current.
- When the user introduces a new question, add it to the main body if it is on-topic; otherwise move it to `Parking Lot`.

## Anti-Drift Rules

- When a new question appears, first decide whether it is directly on-topic or a derived topic.
- If it is on-topic, discuss it and reflect it in the minutes.
- If it is derived, add one line to `Parking Lot` and explicitly note if it is out of scope for this meeting.
- If discussion starts branching into three or more threads, the AI should restate the current `Current Focus`.

## Output Format

Every final meeting output should converge on at least:

### Decisions

- What was decided in this meeting

### Open Questions

- What was intentionally left unresolved

### Action Items

- Who does what by when

### Parking Lot

- Topics intentionally deferred to another time

Use [meeting-end-prompt.md](meeting-end-prompt.md) as the closing template.

## Storage Rules

- Running notes may be updated during the meeting.
- Save only the final version of the minutes.
- Do not save the full raw conversation by default.
- Minutes files use `YYYY-MM-DD-topic-tool.md`.
- `topic` should be short kebab-case.
- The minutes must start with YAML front matter and include at least `title`, `meeting_name`, `topic`, `date`, `timestamp`, `tool`, `meeting_type`, `participants`, `objective`, `constraints`, `started_from_branch`, `branch`, and `status`.
- `timestamp` must use ISO 8601.
- Commit the minutes on the meeting branch, then follow the selected integration path in `rules-version-control`. When direct integration is chosen and merging is authorized, it uses `git merge --no-ff`; a pull-request path follows the same review and merge-authorization requirements.
- Use the user as the reviewer of the local diff before merging.
- `Action Items` stay recorded in the minutes file; there is no separate issue tracker.

## Recommended Flow

1. The user sends the meeting kickoff format.
2. The AI organizes the initial discussion by role and creates the first running memo.
3. As the user asks follow-up questions, the AI updates only the necessary sections of the minutes draft.
4. Side threads go to `Parking Lot`.
5. When the user wants to stop, they use the closing template to request a final version.
6. The AI produces a final draft containing `Decisions`, `Open Questions`, and `Action Items`.
7. If needed, the user requests small corrections and then confirms the final version.
8. Save the final version under `docs/minutes/`.
9. Commit the final version and prepare the selected integration path. After explicit user authorization, integrate with a merge commit and record the rationale per `rules-version-control`; otherwise report that the branch is awaiting merge authorization.

## Start And End Usage

- At the start, use [meeting-start-prompt.md](meeting-start-prompt.md) and send it as the first message.
- `bin/open-meeting` or `start_*_meeting.sh` creates the meeting branch and minutes draft at the start of the meeting.
- During the meeting, the AI keeps running notes and uses `Current Focus` and `Parking Lot` as needed.
- If the discussion touches branch origin, linked worktrees, or current checkout state, the AI should check local Git metadata directly before requesting user help.
- At the end, use [meeting-end-prompt.md](meeting-end-prompt.md) to converge the draft into final minutes.
- If a separate reviewer agent is used, it should review against the user's documented review lens and record either approval or requested changes with `scripts/utils/review-meeting-branch.sh <meeting-branch> --decision <approve|request-changes>` (or `bin/review-meeting`), which only acts on meeting branches not yet merged into the base branch, and records the verdict as a `## Review` section committed on the branch itself.
- Durable document references should use repository-relative paths rather than absolute local filesystem paths.
- For authorized direct integration, finalize the minutes, commit them on the meeting branch, merge the branch into `main` with `git merge --no-ff`, delete the merged branch, and push `main`, per `rules-version-control`. When a pull-request path is selected, follow `rules-version-control` instead of merging locally. Preserve the required reviews, merge authorization, and prohibition on force-pushing for either path.
- If the user communicates meeting closure in natural language, finalize the minutes and prepare integration; proceed to merge only after explicit user authorization.

## Default Close-Out Behavior

When the user clearly indicates that the meeting is ending, the AI should, by default:

1. produce or update the final minutes
2. save the minutes in `docs/minutes/`
3. complete any directly requested work that belongs to the meeting scope
4. commit the resulting changes
5. publish the meeting branch when required by an authorized pull-request workflow; otherwise keep it local until direct integration
6. after explicit user authorization, integrate through the selected direct-merge or pull-request path under `rules-version-control`, preserving all required reviews
7. after successful direct integration, end on `main` and delete the merged meeting branch. A meeting held in a linked worktree is committed there, the worktree is removed, and the merge and push run from the primary worktree, per `rules-version-control` ("Branching and Merging"), which also says why finalized minutes stay unchanged once the branch carries a `## Review`. For a pull-request path, retain the branch until the merge is verified and follow `rules-version-control` for cleanup

Finalize the minutes and prepare the branch without waiting for another prompt. Pause before merging unless explicit user authorization has been given; neither meeting closure nor review approval supplies it. Other blockers include:

- missing required inputs that would make the final minutes misleading
- authentication or network failure during `push` or the `main` merge
- a conflicting working tree state, or a merge conflict against `main`, that cannot be resolved safely

When a real blocker is caused by authentication, authorization, network policy, or another execution restriction that prevents the AI from running a necessary command itself, the AI should not stop at reporting the failure. It should:

1. state exactly which command or action is blocked and why
2. leave the user a single-line command that the CEO / user can run directly
3. explicitly ask the CEO / user to execute that command or complete that action
4. record the pending handoff in `Action Items` when the meeting cannot be fully closed without it

## Automation Model

Prefer one of these two approaches instead of full raw-log auto-save:

- `semi-automatic`: the AI updates running notes during the meeting and produces final Markdown at the end
- `light automation`: generate a template from the meeting name, topic, and tool, update it during the meeting, and finalize it at the end
