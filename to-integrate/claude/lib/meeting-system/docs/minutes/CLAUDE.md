# Minutes

`docs/minutes/` stores final meeting records derived from CLI-based AI conversations.

Examples:

- Claude Code
- other CLI AI agents

## Purpose

- Preserve decisions so they can be reviewed later
- Keep the implementation and research background behind changes
- Make the results reusable for future decisions

## File Naming

Use the following format:

```text
YYYY-MM-DD-topic-tool.md
```

Examples:

```text
2026-03-14-naming-conventions-codex.md
2026-03-14-agent-workflow-claude-code.md
```

`topic` should be short and searchable kebab-case.

## Front Matter Rule

Every minutes file must begin with YAML front matter. The minimum required fields are:

```yaml
title:
meeting_name:
topic:
date:
timestamp:
tool:
meeting_type:
participants:
objective:
constraints:
started_from_branch:
branch:
status:
```

- `timestamp` must use ISO 8601
- metadata selected at meeting start, such as `meeting_type` and `participants`, must always be preserved
- `started_from_branch` is the branch to return to after finalization

## Operating Model

This directory is for final meeting records, not raw logs.

- do not save ordinary conversation
- only save conversations treated as meetings
- drafts may be updated during the meeting
- save only the final confirmed version

See [MEETING-PROTOCOL.md](MEETING-PROTOCOL.md) for the meeting process.

## Recording Principles

- You do not need to paste the full raw log
- The record only needs enough detail to follow topics, decisions, deferred items, and next actions
- Side topics should go to `Parking Lot` instead of bloating the main body
- Add links to source conversation or related files when useful
- Do not preserve confidential secrets in plain form

## Related Files

- [MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [meeting-start-prompt.md](meeting-start-prompt.md)
- [meeting-end-prompt.md](meeting-end-prompt.md)
- [template.md](template.md)

## Standard Commands

Use the following wrappers to start meetings:

```bash
bin/open-meeting
scripts/utils/start-claude-meeting.sh [<meeting-name> <purpose> [constraints] [participants]]
```

`bin/open-meeting` and `start_*_meeting.sh` are the standard flow: they automatically create the meeting branch, `yyyy-mm-dd-hh-mm-discuss_<topic>`, and the initial minutes draft.

Authorized integration, direct or through a pull request, follows `rules-version-control`. The helpers for the local review record:

```bash
bin/review-meeting [<meeting-branch>] --decision <approve|request-changes> [--base-branch <branch>] [--body <text>] [--minutes-file <path>]
bin/approve-meeting [<meeting-branch>] [--base-branch <branch>] [--body <text>] [--minutes-file <path>]
scripts/utils/review-meeting-branch.sh [<meeting-branch>] --decision <approve|request-changes> [--base-branch <branch>] [--body <text>] [--minutes-file <path>]
scripts/utils/approve-meeting-branch.sh [<meeting-branch>] [--base-branch <branch>] [--body <text>] [--minutes-file <path>]
```

`bin/open-meeting` opens the wizard in this order:

```text
1. Which model?
2. What type of meeting?
3. Type-specific meeting name prompt
4. Type-specific purpose or scope prompt
5. Type-specific constraints prompt
6. Who should participate?
```

The prompt wording and defaults change by `meeting_type`:

- `general`
  uses the generic meeting name, purpose, and constraints prompts
- `issue-triage`
  asks for issue-triage-specific naming, scope, and constraints, with defaults for recurring triage sessions
- `report-qa`
  asks for a report Q&A name, the primary user question or report objective, and report-Q&A constraints

Participant choices are loaded from the role `CLAUDE.md` files under `agents/`, default to `all`, and support multi-select with Space.

If you want shorter shell commands, add the repository `bin/` directory to `PATH`:

```bash
export PATH="/home/yunai/working/org/bin:$PATH"
```

See [docs/runbooks/meeting-command-path-setup.md](../runbooks/meeting-command-path-setup.md) for persistent setup.

Then you can run:

```bash
open-meeting
start-claude-meeting [<meeting-name> <purpose> [constraints] [participants]]
review-meeting [<meeting-branch>] --decision <approve|request-changes> [--base-branch <branch>] [--body <text>]
approve-meeting [<meeting-branch>] [--base-branch <branch>] [--body <text>]
```

Use `--dry-run` if you only want to inspect the generated prompt.

## Template

Use [template.md](template.md) for new minutes. Update the draft during the meeting and use [meeting-end-prompt.md](meeting-end-prompt.md) to converge on the final version.

## Reference Link Rule

When embedding repository document links inside durable artifacts such as meeting minutes, review docs, or agent docs:

- use GitHub URLs, not absolute local filesystem paths
- prefer repository-relative paths for stable references in merged docs
- if a document must reference branch-only content before merge, use the branch's GitHub blob URL and normalize it later if needed

## Local Git Workflow

The standard meeting workflow is to create a meeting branch, `yyyy-mm-dd-hh-mm-discuss_<topic>`, at the start. Minutes remain Markdown files in the repository. Direct integration uses `git merge --no-ff`; an authorized pull-request path follows `rules-version-control`. Preserve review requirements and the prohibition on force-pushing for either path.

- `bin/open-meeting` or `start_*_meeting.sh` creates the meeting branch and minutes draft
- update the minutes draft and complete requested work on that branch during the meeting
- for authorized direct integration, finalize the minutes, commit them, merge the branch into `main` with `git merge --no-ff`, delete the merged branch, and push `main`, preserving the reviews required by `rules-version-control`
- `Action Items` stay recorded as plain bullets in the minutes file once confirmed; there is no separate issue tracker
- use `bin/review-meeting` or `scripts/utils/review-meeting-branch.sh` to record reviewer approval or request-changes decisions as a `## Review` section committed on the branch itself
- use `bin/approve-meeting` or `scripts/utils/approve-meeting-branch.sh` to approve an eligible meeting branch
- use the user as the reviewer of the local diff (`git diff main...<meeting-branch>`)

Save the final minutes and report the branch's integration status. If it is awaiting review, merge authorization, or completion of a pull request, keep that status explicit instead of treating the meeting's end as permission to merge.

If the user states that the meeting is over in natural language, finalize the minutes and prepare the selected integration path. Meeting closure and review approval do not authorize merging; obtain explicit user authorization and preserve the review requirements in `rules-version-control`.

## Files

`MEETING-PROTOCOL.md` is the protocol every meeting follows, this file the naming, front-matter, and close-out rules for minutes, `template.md` the minutes template `create-minutes.sh` fills, and `meeting-start-prompt.md` and `meeting-end-prompt.md` the kickoff and close-out prompts. Every other file is one meeting's minutes, named `YYYY-MM-DD-<topic>-<tool>.md`; those are records and keep the names they were written with.
