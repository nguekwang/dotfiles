---
name: issue-tracking
description: Tracking every follow-up a request implies as a GitHub issue and landing the work through a pull request or a merge commit that closes it - filing an issue at intake for each separable deliverable, question, or promised later action, marking what each issue waits on, closing it only through a merged PR or a merge commit on main that names it, or with a stated reason, and resuming a session from the open issues. Use at the intake of any request that produces work, whenever the agent promises a later action, before ending any turn, and whenever the user asks to resume, continue, or pick up earlier work.
---

# Issue Tracking

Record every follow-up a request implies as a GitHub issue in this repository at the moment it arises, and land the work that resolves it through a pull request that closes it. A follow-up that exists only in the agent's intention, in a sentence of a past message, or in a session that has since ended is the defect this rule forbids.

The axis is the lifecycle of one follow-up, in four ordered phases: capture, carry, close, resume. The justification is that a follow-up is lost at exactly one of three moments: it is never written down, its state changes only in the agent's head, or the session holding it ends. An issue lives outside any session and outside any branch, so it survives all three, and a PR that names it closes it at the moment the work lands in `main`. The `conversation-management` skill owns the conversation's agenda and minutes and requires each todo to be tracked durably; this skill is the Environment-layer mechanism that does so in this repository, and the minutes reference the issue number rather than restating it.

This replaces the retired followup ledger at `notes/followups/`.

## Issue Schema

One issue per separable follow-up, in this repository. Write it in English, per the `language-selection` skill, because an issue is a durable internal record.

- Title: a verb infinitive plus its object ("Move notes/languages/ to Google Drive"), short enough to read in a list. `.github/ISSUE_TEMPLATE/task.yml` sets the form and `.github/workflows/enforce-templates.yml` closes a non-conforming issue as not planned.
- Body: it begins with `### Why` (the goal in one line; the workflow closes an issue whose body does not begin with it), then the headings `### What` (what is to be done, concretely enough that a session with no memory of the conversation can start), `### Where` (the files or skills it touches), and `### Done when` (the completion condition), then a `**Waiting on:**` line when someone other than the agent holds the next action. Issues filed through `gh` or the GitHub MCP tools use the same headings. After filing, tie the wait to that issue: read its `createdAt` (`gh issue view <n> --json createdAt`), poll `gh run list --workflow enforce-templates.yml --event issues --json databaseId,createdAt,status,displayTitle` until a run appears that was created at or after that time and whose `displayTitle` is the issue's title (the workflow sets `run-name` to it; a run is not listed at once, so retry every few seconds), and `gh run watch` that run's `databaseId`. Give up after about 2 minutes without such a run: tell the user the template check could not be confirmed and carry the issue as filed but not checked, rather than waiting longer. Otherwise confirm the issue is still open (`gh issue view <n> --json state`); if the workflow closed it, refile it corrected.
- Grouping: a request that yields several related issues gets a parent tracking issue, and each item is created as its sub-issue. Do not invent labels; use only labels that already exist in the repository.
- Footer: end the body with the attribution footer the environment requires for GitHub posts.

The state axis is who holds the next action, and it is exhaustive:

- Open without a `Waiting on:` line: the agent holds the next action. A turn may end on such an issue only when the closing message names it as carried over to the next session, per Close the Turn.
- Open with a `**Waiting on:**` line: a named person or event holds the next action. The line names the trigger concretely: a person ("the user sets the threshold"), an event ("the private repository exists"), or a time.
- Closed as completed: the work landed in `main` through a merged PR or a `--no-ff` merge commit that names the issue, or needed no code and was verified.
- Closed as not planned by the workflow: `enforce-templates.yml` closed an issue that did not follow the template; its closing comment begins `Closed: does not follow the issue template`. This is a filing error, not an abandonment: refile it corrected, and do not count it as a decision.
- Closed as not planned by a decision: the item was abandoned (never a workflow closure), with the reason stated to the user and in a closing comment, never decided silently.

## Capture at Intake

Decompose the request into issues before starting work, in the same turn the request arrives. File the implied follow-ups, not only the stated ones. The axis of decomposition is the kind of follow-up a request carries:

- Stated deliverables: each thing the user asked for, one issue per separable deliverable.
- Implied completion steps that outlive the turn: a verification that can only run later, cleanup the environment leaves behind. Steps finished in the same turn (the commit, the push) need no issue.
- Questions the user asked that are not answered in this turn.
- Promises the agent makes: every sentence of the form "later", "after X", "in the next step", "once you confirm" becomes an issue at the moment it is written. A promise without an issue is prohibited.

A request finished completely within one turn, leaving nothing behind, needs no issue. Search the open issues before filing, so one follow-up never has two issues.

## Carry Through the Work

Change an issue's state at the moment its state changes, not at the end of the turn from memory.

- Do the work on a topic branch per the `rules-version-control` skill. When the work lands through a pull request, its description says `Closes #<n>` for each issue it resolves. When it lands through a local `git merge --no-ff` and `git push origin main`, the merge commit message, the change record per that skill's "Merge Commit Message", carries the same `Closes #<n>` lines, so GitHub closes the issues when the commit reaches `main`.
- After the work reaches `main`, confirm each resolved issue shows as closed. If one is still open, close it by hand as completed, with a comment naming the merge commit.
- Add or remove the `**Waiting on:**` line by editing the body when the next action leaves or returns to the agent's hands; a comment explains what changed.
- Never delete an issue. A wrong issue is closed as not planned with the reason.

## Close the Turn

Before ending a turn, confirm all of the following. The check covers the issues this session filed or took up; open issues from earlier sessions that this session did not work on are carried over unchanged.

- Every issue this session filed or took up and still holds was resolved, moved to waiting with its trigger, or closed with its reason (a closure by decision; one by the workflow is refiled), or is named in the closing message as carried over to the next session.
- Every promise made in this turn's messages has an issue.
- No issue this session filed was closed by the workflow without being refiled.
- The closing message lists the issues this session filed or took up that are still open, with their numbers and triggers (or the carry-over note). Open issues from earlier sessions are not listed, since the SessionStart hook shows them, so the user sees what the agent is holding and on what. A closing message that says the work is complete while a waiting issue exists is prohibited.

## Resume a Session

A session resumes from the open issues, not from the user's memory. The SessionStart hook `.claude/hooks/list-open-issues.py` prints the open issues when the `gh` CLI is available and authenticated; where it is not, list them with the GitHub MCP tools.

- When the user asks to resume, continue, or pick up earlier work, the open issues are the work. Start on them; never reply by asking what should be resumed while open issues exist.
- A waiting issue whose trigger has fired (the user answered, the event happened) loses its `Waiting on:` line and is the agent's again.
- If the user's ask is new, file issues for it and leave the earlier open issues as they are; the SessionStart hook keeps showing them.

## Verification

Before ending any turn, confirm: every follow-up the request implied has an issue; every issue this session filed or took up is resolved, waiting, closed, or named as carried over; every waiting issue names its trigger; every issue closed as not planned by a decision names its reason and the user heard it; no issue this session filed was closed by the workflow without being refiled; every PR or merge commit names the issues it closes, and each resolved issue shows as closed after the push to `main`; the closing message lists the issues this session filed or took up that are still open. The residual is a session that cannot reach GitHub: then the closing message itself carries the follow-ups as a list of titles and bodies, so the next session can file them.
