#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

usage() {
  cat <<'EOF'
usage: start-meeting-branch.sh <topic> [base-branch]

Creates and checks out a meeting branch, yyyy-mm-dd-hh-mm-discuss_<topic>,
from the given base branch.
Requires git and a clean enough worktree to create a new branch.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

topic="$1"
base_branch="${2:-main}"

if [[ ! "$topic" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "topic must be kebab-case: $topic" >&2
  exit 1
fi

git rev-parse --show-toplevel >/dev/null

current_branch="$(git branch --show-current)"
branch_name="$(meeting_branch_name "$topic")"
start_point=""

if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  echo "branch already exists: ${branch_name}" >&2
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

git switch -c "${branch_name}" "${start_point}"

printf 'created %s from %s (previous branch: %s)\n' "${branch_name}" "${start_point}" "${current_branch:-detached-head}"
