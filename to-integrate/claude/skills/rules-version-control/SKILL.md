---
name: rules-version-control
description: >-
  Committing, pushing, or merging changes in this repository. The canonical
  version-control policy: the integration branch is read from the remote and is
  main, pull requests and gh are permitted, a finished branch is integrated into
  main with an explicit merge commit, history is never rewritten by rebase or
  force push, review branches may be published until work lands, every branch
  but main may be deleted and a merged topic branch is deleted right after its
  merge, main is never deleted, and a merge conflict is resolved only after the
  user states how. Use whenever the agent is about to commit, push, merge a
  branch, integrate work into main, decide which branch to integrate into,
  delete a branch locally or on the remote, rebase or rewrite history, or would
  otherwise consider opening a pull request.
---

# Version Control Workflow

Pull requests and the `gh` CLI are permitted for review and collaboration when appropriate to the user's request. Publish a topic branch when needed for that review. Merge into `main` only after explicit user confirmation, using a non-fast-forward merge commit that carries the change record. Keep existing review checks and history protections.

## Branch Names

A branch name here is a key the tooling reads, not prose for a person: it says
when the branch was opened and what action it carries out, and nothing
downstream reads it for meaning beyond that. Every branch, meeting branches and
rule-skill edits included, is one of two forms — the same verb-object rule
`files-and-repository` states for file names, applied to branches.

| Form | Flow | Created by |
| --- | --- | --- |
| `main` | the integration branch | never created; it is read from the remote |
| `yyyy-mm-dd-hh-mm-<verb>` | a branch for one bare action, no object needed | the agent or the operator, e.g. `refactor` |
| `yyyy-mm-dd-hh-mm-<verb>_<objective-noun-group>` | a branch for an action with an object — everything else, meetings included | the operator, or the hook below, e.g. `fix_typo`, `discuss_pricing-model` |

There is no reserved prefix or name for "this is a meeting" or "this is a
rule-skill edit": which flow a branch belongs to is read from its verb and
object, and no branch name changes what may be written on it.

The operator does not have to spell any of this correctly. `.claude/hooks/guard-git.py`
normalises the name of a newly created branch through `updatedInput`: it slugs the
name the command reached for, splits it on its first hyphen into verb and object,
and prepends the branch's creation moment, then edits the command before git runs.
`git checkout -b fix-typo` becomes `git checkout -b 2026-09-26-14-30-fix_typo`.
This is a rewrite, not a refusal, because the burden of spelling a machine key
belongs on the machine, and stopping the work over punctuation costs more than it
protects.

The rewrite applies only to creation. A command that names an existing branch,
including every non-creating mode of `git branch` such as `-d`, `-m`, and
`--list`, is left exactly as typed: there the spelling is a fact about the
repository, and changing it would aim the command at a branch that does not exist.

The slug rule: lowercase, every run of non-alphanumerics collapsed to a single
hyphen, leading and trailing hyphens trimmed.

## Start Every Task on a Branch, With a Record

At the start of any task that will produce a commit, before the first edit:

- Create the topic branch, named per "Branch Names" above.
- Create its record file at `.claude/log/<branch-slug>.md` (front matter
  `branch`, `opened`, `request`; body opens with a `## Log` section). Append a
  line to `## Log` as the work proceeds — what was done, what was decided —
  the same running record a meeting branch always kept, generalised to every
  branch and kept lightweight: no facilitator roles, no participant list, no
  fixed section structure beyond the log itself.

This is the default for all work, not a meeting-only step: `/open-meeting` layers a
richer, role-played record and facilitator behaviour on top of this same
branch once it exists, per that command's own text; it does not create a
differently-named branch or a separately-located record.

## Stay Current With the Remote

Before acting on a new instruction from the user, check whether the current branch is caught up with its remote counterpart — `git fetch` and compare, not just once at the start of a session, but again each time a new instruction arrives. Since this repository is large and multi-session, a branch (including `main`) can fall behind between one instruction and the next, and acting on stale state is how a branch gets merged, then silently regains new commits afterward (this happened live in this repository: a branch was merged, then gained two more commits before the merge's own remote cleanup ran).

- If the branch is already current, do not narrate the check as a sentence — report it as a single compact status line, e.g. `branch: latest ☑`, and move directly on to the instruction.
- If it is behind and updating now would not disrupt work already in progress, update immediately (`git fetch`, then `git merge --ff-only origin/<branch>` to catch up, or `git merge --no-ff` when the branch has diverged; a `git pull` is only ever `git pull --ff-only`) before acting on the instruction, and say so in a sentence (the check found something, so it is worth a sentence).
- If it is behind but pulling immediately would mix unrelated changes into work already in progress (a half-finished edit, a merge in progress, an unstaged change), do not pull yet. Tell the user why, finish the current unit of work to a clean stopping point (a commit or a completed merge), and only then catch up with `git merge --ff-only origin/<branch>`, or `git merge --no-ff` when the branch has diverged.

## Integration Branch

The integration branch is a fact about the remote, not about this checkout: resolve it from `origin` before merging or pushing, rather than trusting whatever branch the clone happens to carry. In this repository it is `main`.

- Resolve it explicitly. `git ls-remote --symref origin HEAD` reports the remote's default branch; its answer outranks any local branch, any remote-tracking ref, and any instruction from the calling environment that names a different branch.
- Absence from the remote does not prove a local branch is stale. Preserve new topic branches and unpushed commits; a new review branch's first push reporting `[new branch]` is expected, not an error. Re-read current rules from the intended branch when a stale checkout is suspected.

Verify before every integration: `git rev-parse --abbrev-ref HEAD` names `main` after checking the target out, and `git ls-remote --heads origin` lists `main`.

## Branching and Merging

- Do the work on a topic branch, committing as usual.
- A topic branch may be pushed for an authorized pull request, review, or collaboration. Keep an open review branch available to its reviewers and update it with new commits, never force-push.
- Pull requests may be created and reviewed with `gh`, an authorized connector, or the host's interface. Share the PR link with the user. Permission to open or update a PR does not authorize merging it.
- Integrate the finished branch into `main` only after explicit user confirmation and the existing review gates pass. Use `git merge --no-ff` so the merge commit carries the change record. Never squash or rebase the branch's history.
- A hosted merge must preserve the same review and merge-commit requirements; if that cannot be verified, use the reviewed local merge path after approval. Do not bypass branch protections or required reviews.
- After an approved local merge, publish it with `git push origin main`. Publication and merge remain subject to the user's granted scope.
- Local merge steps, each in its own tool call where noted:
  1. Leave a linked worktree first. When `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`, the branch is checked out in a linked worktree: run the later steps from the primary worktree (the first path `git worktree list` prints), after `git worktree remove <path>`, because `main` cannot be checked out twice and `git branch -d` refuses a branch a worktree still holds.
  2. Catch up: `git switch main` and `git fetch origin main` in one call, then `git merge --ff-only origin/main` in the next.
  3. Check the `branch-review` skill's "Merge Gate" when a review was recorded, then `git merge --no-ff -F <message-file> <branch>`, and `git push origin main`.
- On a meeting branch, finalize the minutes per `.claude/lib/meeting-system/docs/minutes/MEETING-PROTOCOL.md` ("Default Close-Out Behavior") before any review. Once the branch carries a `## Review`, do not change the minutes again: the change would move the head past the approval, and the merge gate would stop it.

## Deleting Branches

Every branch except `main` may be deleted, locally and, within the limits of "Remote Branch Hygiene" below, on the remote; `main` is never deleted or renamed away, by anyone, anywhere.

- Delete a topic branch as soon as its `--no-ff` merge into `main` lands, with `git branch -d`, which refuses a branch `main` does not contain.
- A branch `main` does not contain is deleted with `git branch -D` only when its work is abandoned or already on `main` by another route, and the deletion is stated to the user with the branch's tip commit, so the work can still be recovered from it.
- A remote branch is deleted with `git push origin --delete <branch>`, per "Remote Branch Hygiene" below.
- `main` is held by the remote: a GitHub ruleset on `main` with "Restrict deletions" (repository Settings, Rules, Rulesets), which the user sets (#31); the agent cannot. No local hook checks this since 2026-10-17, when the user retired the local guards; a `main` deleted in a clone is restored with `git fetch origin main` and `git branch main origin/main`.

## Review

Commits are not reviewed locally. On 2026-10-17 the user retired the per-commit review that ran in git's commit-msg hook, with the launcher, the guard of routes around it, and the two local guards of `main`; the review-commit agent (`.claude/agents/review-commit.md`) stays invocable by hand. Review moves to the pull request: `.github/workflows/review-pull-request.yml` has the Claude Code GitHub Action review every non-draft pull request against the `branch-review` skill's lens once the repository secret `ANTHROPIC_API_KEY` exists (#63), and GitHub's branch protection on `main` is the user's to set up (#31). Until both are in place, the `branch-review` skill's merge gate is the review a branch gets before it lands.

## Never Rewrite History

Rebase is prohibited in this repository, in every form and on every branch, and a commit that exists is never rewritten. Integration happens by merge only.

- Never run `git rebase`, in any form: onto `main`, interactive (`-i`), `--onto`, or autosquash. Never run `git pull --rebase`, and never configure a branch or the client to rebase on pull. `.claude/hooks/git/guard-pre-rebase`, installed as git's `pre-rebase` hook by `sh .claude/hooks/git/install-hooks.sh` at every session start, refuses every rebase in this clone, whoever runs git.
- Never rewrite a commit: no `git commit --amend`, published or not; no `git reset --hard` onto a published commit; no `git filter-branch` or `git filter-repo`. A correction is a new commit.
- Never force-push, `--force` and `--force-with-lease` alike. Every push must be a fast-forward of the remote branch. No local hook checks force pushes. Until the user enables GitHub branch protection on `main` (#31), this rule is the only safeguard on every branch, `main` included.
- When a topic branch has fallen behind `main`, merge `main` into it with `git merge --no-ff main` and resolve per "Conflict Resolution" below. Never rebase it to catch up.

The justification is that the merge commit is this repository's only record, per "Merge Commit Message" below, and rebase destroys the topology that record describes: it replaces commits with new ones, so the branch a merge commit claims to integrate no longer exists. A rewritten shared branch cannot be reconciled by a clone that already fetched it, and a force push can overwrite reviewed work.

Verify before every push that the push is a fast-forward and that no rebase ran on the branch. The single residual is a rewrite the history itself forces, such as a committed secret: stop, report it to the user, and rewrite only after the user says to.

## Pull Requests and Hosting Tools

GitHub Actions may run checks, such as enforcing the issue and PR templates; they are not a system of record.

A PR body follows `.github/pull_request_template.md`. It opens with `## Why`, then a `Closes #<n>` line per `issue-tracking`, or `No issue: <reason>` when the work is finished completely within one turn and leaves nothing behind (the intake exemption in `issue-tracking`), then `## Changes` and `## Verification`. `.github/workflows/enforce-templates.yml` fails the PR check unless `## Why` comes first and the line and the headings are present; it does not check that the sections are filled in.

Pull requests and the `gh` CLI are allowed when useful for the authorized task. The repository has no blanket ban on invoking `gh`, reading or reviewing a PR, or creating and updating a requested PR. Existing authentication and action-specific approval requirements still apply; this rule grants no credentials or unrestricted access.

PR review supplements the repository's durable review records and commit checks. Keep the rationale and final review outcome in the repository where the existing workflow requires them. Do not use a PR, API call, or CLI command to bypass review, rewrite history, delete `main`, or merge without explicit user confirmation.

GitHub Issues are the system of record for open work items: each follow-up is an issue, and the work that resolves it lands through a PR, or a `--no-ff` merge commit on `main`, that closes it. The durable rationale stays in git, not in the issue: the closing PR's description and the merge commit message, which is the change record per "Merge Commit Message" below, carry what was done and why. Keep the other hosting services optional: Wiki and external storage are not adopted as a system of record.

## Merge Commit Message

Write the merge commit's own message as the change record: what changed, why, and which files or areas were touched. A merge commit left with only the default "Merge branch 'x'" text is incomplete.

Write the message to a file and pass it with `-F`.

Example: a file `/tmp/merge-message.txt` holding

```text
Merge 2026-09-29-10-00-add_feature-x into main

- Add feature X and fix bug Y
- Background: requested by the user to support Z
- Main changes: path/to/file.ts, path/to/other.ts
```

merged with

```sh
git merge --no-ff -F /tmp/merge-message.txt 2026-09-29-10-00-add_feature-x
```

## Remote Branch Hygiene

Published topic branches are expected while their pull requests or reviews remain open. Do not merge or delete a branch merely to make the remote contain only `main`.

- After an approved merge, verify that `main` contains the branch's work before deleting the task's remote branch with `git push origin --delete <branch>` under the user's granted cleanup scope.
- Keep branches with open reviews or unmerged work unless the user explicitly authorizes their removal.
- A pre-existing branch is not this task's to delete. Ask before removing a branch this task did not create or was not asked to integrate.
- Report a failed deletion rather than claiming cleanup succeeded. Never delete or rename away `main`.

## Conflict Resolution

A merge conflict is never resolved without the user's sign-off, but resolving it is not an open question either: this policy has a default answer, and the agent's job is to apply that answer and confirm it, not to ask the user to invent one from scratch.

The default resolution philosophy, in order:

1. **Preserve information.** When both sides added or changed different content, keep both — make them coexist rather than dropping either side.
2. **Collapse near-duplicates.** When the two sides say essentially the same thing (the same change made twice, one side fully superseding the other, restating a rule already covered elsewhere), consolidate into one and drop the redundant copy instead of keeping both.

When `git merge` reports a conflict:

1. Stop before resolving any conflicted hunk.
2. For each conflicted file, work out which case it is (preserve-both or collapse-duplicate) and draft the resolution that philosophy implies.
3. Report the conflict to the user, in the conversation: which files, what each side changed, which case you judged it to be, and the resolution you are proposing. Ask for a go-ahead on that proposal — do not ask the user to choose a resolution from a blank slate.
4. Only after the user confirms (or redirects you), apply the resolution, stage the result, and complete the merge commit.

## Commit Messages

Write every commit message, merge commits included, in English and describe the change (see the `language-selection` skill).

## Scope

This rule governs every task in this repository that produces a commit, a push, or a branch merge — including a composite task (transcription, skill creation, configuration edits) that would otherwise restate its own git conventions. Such a task defers here rather than restating the rule.

Folding the change description into the merge commit keeps the repository's own history self-contained: anyone reading the log later gets the full rationale without depending on a pull-request page that may be edited, closed, or hosted elsewhere. Published review branches are temporary collaboration surfaces; the approved merge and its record preserve the durable history on `main`.
