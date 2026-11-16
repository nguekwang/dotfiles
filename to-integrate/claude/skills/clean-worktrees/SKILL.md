---
name: clean-worktrees
description: Clean up finished meeting worktrees
disable-model-invocation: true
---

# /clean-worktrees

Run `.claude/lib/meeting-system/bin/clean-worktrees` (or `.claude/lib/meeting-system/scripts/utils/clean-meeting-worktrees.sh $ARGUMENTS[0]`) to remove the linked worktrees of meeting branches already merged into the base branch. This is destructive — confirm with the user before removing any worktree that has uncommitted changes.

Usage: `/clean-worktrees [base-branch]`

Base branch the meeting branches are checked against (optional, default `main`): $ARGUMENTS[0]
