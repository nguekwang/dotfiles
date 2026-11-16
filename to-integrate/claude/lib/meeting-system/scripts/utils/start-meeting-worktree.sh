#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

usage() {
  cat <<'EOF'
usage: start-meeting-worktree.sh <topic> [base-branch] [worktree-root]

Creates a meeting branch, yyyy-mm-dd-hh-mm-discuss_<topic>, as a linked worktree.
EOF
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

topic="$1"
base_branch="${2:-main}"
worktree_root="${3:-}"

if [[ ! "$topic" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "topic must be kebab-case: $topic" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
branch_name="$(meeting_branch_name "$topic")"
worktree_name="${branch_name}"

if [[ -z "$worktree_root" ]]; then
  worktree_root="$(cd "$repo_root/.." && pwd)/.worktrees"
fi

worktree_path="${worktree_root}/${worktree_name}"
start_point=""

if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  echo "branch already exists: ${branch_name}" >&2
  exit 1
fi

if [[ -e "$worktree_path" ]]; then
  echo "worktree path already exists: ${worktree_path}" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${base_branch}"; then
  start_point="${base_branch}"
else
  git fetch --quiet origin "${base_branch}" || true
  if git show-ref --verify --quiet "refs/remotes/origin/${base_branch}"; then
    start_point="origin/${base_branch}"
  else
    echo "base branch not found locally or on origin: ${base_branch}" >&2
    exit 1
  fi
fi

mkdir -p "$worktree_root"
git worktree add -b "${branch_name}" "$worktree_path" "${start_point}" >/dev/null

printf '%s\n' "$worktree_path"
