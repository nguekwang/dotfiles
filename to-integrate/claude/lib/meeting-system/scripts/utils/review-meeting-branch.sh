#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

usage() {
  cat <<'EOF'
usage: review-meeting-branch.sh [<meeting-branch>] --decision <approve|request-changes> [--base-branch <branch>] [--body <text>] [--minutes-file <path>]

Records a reviewer decision for a meeting branch directly in its minutes
file, as a `## Review` section committed on the branch itself. No GitHub PR
is involved. Only acts on meeting branches (yyyy-mm-dd-hh-mm-discuss_<topic>) that are not already
merged into the base branch.
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

meeting_branch=""
decision=""
base_branch="main"
body=""
minutes_file=""

if [[ $# -gt 0 && "$1" != --* ]]; then
  meeting_branch="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --decision)
      decision="${2:-}"
      [[ -n "$decision" ]] || { usage >&2; exit 1; }
      shift 2
      ;;
    --base-branch)
      base_branch="${2:-}"
      [[ -n "$base_branch" ]] || { usage >&2; exit 1; }
      shift 2
      ;;
    --body)
      body="${2:-}"
      shift 2
      ;;
    --minutes-file)
      minutes_file="${2:-}"
      [[ -n "$minutes_file" ]] || { usage >&2; exit 1; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

case "$decision" in
  approve|request-changes)
    ;;
  *)
    echo "invalid decision: $decision" >&2
    exit 1
    ;;
esac

git -C "$ROOT_DIR" rev-parse --show-toplevel >/dev/null
repo_root="$(git -C "$ROOT_DIR" rev-parse --show-toplevel)"
cd "$repo_root"

if [[ -z "$meeting_branch" ]]; then
  meeting_branch="$(git branch --show-current)"
fi

if ! is_meeting_branch "$meeting_branch"; then
  echo "branch is not a meeting branch (yyyy-mm-dd-hh-mm-discuss_<topic>): $meeting_branch" >&2
  exit 1
fi

if ! git rev-parse --verify "$meeting_branch" >/dev/null 2>&1; then
  echo "branch not found: $meeting_branch" >&2
  exit 1
fi

if git merge-base --is-ancestor "$meeting_branch" "$base_branch" 2>/dev/null; then
  echo "branch is already merged into $base_branch: $meeting_branch" >&2
  exit 1
fi

if [[ -z "$minutes_file" ]]; then
  topic="$(meeting_topic "$meeting_branch")"

  shopt -s nullglob
  candidates=("$ROOT_DIR"/docs/minutes/*-"${topic}-"*.md)
  shopt -u nullglob

  case "${#candidates[@]}" in
    0)
      echo "no minutes file found for branch topic: $topic" >&2
      exit 1
      ;;
    1)
      minutes_file="${candidates[0]}"
      ;;
    *)
      echo "multiple minutes files found for branch topic; pass --minutes-file explicitly" >&2
      printf '  %s\n' "${candidates[@]}" >&2
      exit 1
      ;;
  esac
fi

if [[ ! -f "$minutes_file" ]]; then
  echo "minutes file not found: $minutes_file" >&2
  exit 1
fi

current_checkout="$(git branch --show-current)"
git switch "$meeting_branch"

{
  printf '\n## Review\n\n'
  printf -- '- decision: %s\n' "$decision"
  printf -- '- reviewed_at: %s\n' "$(date -Iseconds)"
  if [[ -n "$body" ]]; then
    printf -- '- notes: %s\n' "$body"
  fi
} >> "$minutes_file"

git add "$minutes_file"
git commit -m "Record review (${decision}) for ${meeting_branch}"

if [[ -n "$current_checkout" && "$current_checkout" != "$meeting_branch" ]]; then
  git switch "$current_checkout"
fi

printf 'recorded %s review for %s in %s\n' "$decision" "$meeting_branch" "$minutes_file"
