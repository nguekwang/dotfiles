#!/usr/bin/env bash

# branch-review.sh: git-native code review of a local topic branch.
#
#   show    <branch> [--base <b>]
#           Print the reviewer's input: commit list, file stat, full diff.
#   record  <branch> --decision <approve|request-changes> --findings <file>
#           [--base <b>] [--reviewer <name>]
#           Append a review round to .claude/reviews/<ts>-<slug>.md and
#           commit it on the branch.
#   verdict <branch> [--base <b>]
#           Exit 0 if the latest round is approve and the branch head is that
#           round's record commit, 1 if not, 2 if no record exists.
#
# No pull request, issue, or hosted review is involved; see the
# rules-version-control skill.

set -euo pipefail

usage() {
  sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() {
  echo "branch-review: $*" >&2
  exit 1
}

slug_of() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# Path of the record file as committed on the branch, or empty.
record_path_on() {
  local branch="$1" slug="$2"
  git ls-tree -r --name-only "$branch" -- .claude/reviews 2>/dev/null \
    | grep -E "^\.claude/reviews/[0-9]{14}-${slug}\.md$" | head -n 1 || true
}

check_branch() {
  local branch="$1" base="$2"
  git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null \
    || die "branch not found: $branch"
  git rev-parse --verify --quiet "$base" >/dev/null \
    || die "base not found: $base"
  [[ "$branch" != "$base" ]] || die "branch and base are the same: $branch"
  if git merge-base --is-ancestor "$branch" "$base"; then
    die "branch is already merged into $base: $branch"
  fi
}

cmd_show() {
  local branch="$1" base="$2"
  check_branch "$branch" "$base"
  local merge_base
  merge_base="$(git merge-base "$base" "$branch")"
  printf '# branch: %s\n# base: %s\n# range: %s..%s\n\n' \
    "$branch" "$base" "$(git rev-parse --short "$merge_base")" "$(git rev-parse --short "$branch")"
  printf '## Commits\n\n'
  git log --format='%h %ad %an %s' --date=short "$base..$branch"
  printf '\n## Stat\n\n'
  git diff --stat "$base...$branch"
  printf '\n## Diff\n\n'
  git diff "$base...$branch"
}

cmd_record() {
  local branch="$1" base="$2" decision="$3" findings="$4" reviewer="$5"
  check_branch "$branch" "$base"
  case "$decision" in
    approve|request-changes) ;;
    *) die "invalid decision: $decision (approve|request-changes)" ;;
  esac
  [[ -n "$findings" ]] || die "--findings <file> is required"
  [[ -f "$findings" ]] || die "findings file not found: $findings"
  [[ -z "$(git status --porcelain)" ]] || die "working tree is not clean; commit or stash first"

  local slug head path round
  slug="$(slug_of "$branch")"
  head="$(git rev-parse "$branch")"
  path="$(record_path_on "$branch" "$slug")"
  [[ -n "$path" ]] || path=".claude/reviews/$(date +%Y%m%d%H%M%S)-${slug}.md"

  local previous
  previous="$(git branch --show-current)"
  git switch --quiet "$branch"
  # Review records live under .claude/reviews/, which the repository tracks.
  # They are still force-added, so a record is committed even in a checkout
  # whose ignore rules would otherwise hide it. An EXIT trap restores the starting branch on any
  # failure while the record is written (including one `set -e` triggers), so
  # a broken record never leaves the checkout stranded. It is cleared just
  # before the record commit, so a commit the review refuses leaves the
  # checkout on the reviewed branch with the record staged there.
  if [[ -n "$previous" && "$previous" != "$branch" ]]; then
    trap 'git switch --quiet "$previous" 2>/dev/null || true' EXIT
  fi

  mkdir -p .claude/reviews
  if [[ ! -f .claude/reviews/CLAUDE.md ]]; then
    cat > .claude/reviews/CLAUDE.md <<'EOF'
# .claude/reviews

Review records written by the `branch-review` skill: one file per reviewed
topic branch, named `<yyyymmddhhmmss>-<branch-slug>.md`, with one `## Round n`
section per review round. The latest round's `decision` gates the merge. Never
edit a record by hand; append a round through the skill's script.
EOF
    git add -f .claude/reviews/CLAUDE.md
  fi

  if [[ ! -f "$path" ]]; then
    printf '# Review: %s\n\n- base: %s\n' "$branch" "$base" > "$path"
    round=1
  else
    round=$(( $(grep -c '^## Round ' "$path") + 1 ))
  fi

  {
    printf '\n## Round %s\n\n' "$round"
    printf -- '- decision: %s\n' "$decision"
    printf -- '- reviewed_at: %s\n' "$(date -Iseconds)"
    printf -- '- reviewer: %s\n' "$reviewer"
    printf -- '- head: %s\n' "$head"
    printf -- '- findings:\n\n'
    cat "$findings"
    printf '\n'
  } >> "$path"

  git add -f "$path"
  # The commit goes through the commit review of rules-version-control, which can
  # refuse it. The exit trap would then carry the staged record back to the
  # starting branch, so it is cleared first: on a refusal the checkout stays on
  # the reviewed branch, with the record staged where it belongs.
  trap - EXIT
  if ! git commit --quiet -m "Record review round ${round} (${decision}) for ${branch}"; then
    printf 'branch-review: the commit review refused the record commit. The checkout stays on %s with %s staged: fix what the review names, commit there with git commit, then git switch %s.\n' \
      "$branch" "$path" "${previous:-back}" >&2
    exit 1
  fi

  if [[ -n "$previous" && "$previous" != "$branch" ]]; then
    git switch --quiet "$previous"
  fi
  printf 'recorded round %s (%s) for %s in %s\n' "$round" "$decision" "$branch" "$path"
}

cmd_verdict() {
  local branch="$1" base="$2"
  check_branch "$branch" "$base"
  local slug path decision record_commit head
  slug="$(slug_of "$branch")"
  path="$(record_path_on "$branch" "$slug")"
  if [[ -z "$path" ]]; then
    echo "no review record on $branch"
    exit 2
  fi
  decision="$(git show "$branch:$path" | sed -n 's/^- decision: //p' | tail -n 1)"
  record_commit="$(git log -1 --format=%H "$branch" -- "$path")"
  head="$(git rev-parse "$branch")"
  printf 'record: %s\nlatest decision: %s\n' "$path" "$decision"
  if [[ "$decision" != "approve" ]]; then
    echo "verdict: not approved"
    exit 1
  fi
  if [[ "$record_commit" != "$head" ]]; then
    echo "verdict: head moved after the latest round ($(git rev-parse --short "$record_commit") -> $(git rev-parse --short "$head")); review again"
    exit 1
  fi
  echo "verdict: approved"
}

main() {
  [[ $# -ge 1 ]] || { usage >&2; exit 1; }
  local cmd="$1"; shift
  case "$cmd" in
    -h|--help|help) usage; exit 0 ;;
    show|record|verdict) ;;
    *) usage >&2; exit 1 ;;
  esac

  local branch="" base="main" decision="" findings="" reviewer=""
  if [[ $# -gt 0 && "$1" != --* ]]; then
    branch="$1"; shift
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base) base="${2:-}"; [[ -n "$base" ]] || die "--base needs a value"; shift 2 ;;
      --decision) decision="${2:-}"; [[ -n "$decision" ]] || die "--decision needs a value"; shift 2 ;;
      --findings) findings="${2:-}"; [[ -n "$findings" ]] || die "--findings needs a value"; shift 2 ;;
      --reviewer) reviewer="${2:-}"; [[ -n "$reviewer" ]] || die "--reviewer needs a value"; shift 2 ;;
      *) usage >&2; exit 1 ;;
    esac
  done
  [[ -n "$branch" ]] || branch="$(git branch --show-current)"
  [[ -n "$branch" ]] || die "no branch given and HEAD is detached"
  [[ -n "$reviewer" ]] || reviewer="$(git config user.name || echo unknown)"

  cd "$(git rev-parse --show-toplevel)"
  case "$cmd" in
    show) cmd_show "$branch" "$base" ;;
    record) cmd_record "$branch" "$base" "$decision" "$findings" "$reviewer" ;;
    verdict) cmd_verdict "$branch" "$base" ;;
  esac
}

main "$@"
