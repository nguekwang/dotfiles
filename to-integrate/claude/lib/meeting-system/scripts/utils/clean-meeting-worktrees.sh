#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

usage() {
  cat <<'EOF'
usage: clean-meeting-worktrees.sh [base-branch]

Removes linked meeting worktrees whose branches are already merged into the base branch.
EOF
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

base_branch="${1:-main}"
repo_root="$(git rev-parse --show-toplevel)"
current_branch="$(git branch --show-current)"

if ! git show-ref --verify --quiet "refs/heads/${base_branch}"; then
  git fetch --quiet origin "${base_branch}" || true
fi

git worktree prune >/dev/null

git worktree list --porcelain | awk '
  /^worktree / { path=substr($0, 10); next }
  /^branch refs\/heads\// { branch=substr($0, 19); print branch "\t" path }
' | while IFS='	' read -r branch path; do
  is_meeting_branch "$branch" || continue
  [[ "$path" == "$repo_root" ]] && continue
  if [[ "$branch" == "$current_branch" ]]; then
    continue
  fi
  if git merge-base --is-ancestor "$branch" "$base_branch"; then
    git worktree remove "$path"
    printf 'removed %s\t%s\n' "$branch" "$path"
  fi
done
