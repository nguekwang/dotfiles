#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

git rev-parse --show-toplevel >/dev/null

# Each meeting branch checked out in a worktree, as `<branch>\t<path>`.
git worktree list --porcelain | awk '
  /^worktree / { path=substr($0, 10); next }
  /^branch refs\/heads\// { print substr($0, 19) "\t" path }
' | while IFS='	' read -r branch path; do
  if is_meeting_branch "$branch"; then
    printf '%s\t%s\n' "$branch" "$path"
  fi
done
exit 0
