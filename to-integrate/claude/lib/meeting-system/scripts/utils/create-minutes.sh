#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 8 || $# -gt 9 ]]; then
  echo "usage: $0 <topic> <tool> <title> <objective> <meeting-type> <constraints> <participants> <started-from-branch> [status]" >&2
  exit 1
fi

topic="$1"
tool="$2"
title="$3"
objective="$4"
meeting_type="$5"
constraints="$6"
participants="$7"
started_from_branch="$8"
status="${9:-draft}"
started_from_path="${MEETING_STARTED_FROM_PATH:-$(pwd)}"
workspace_mode="${MEETING_WORKSPACE_MODE:-branch-only}"
worktree_path="${MEETING_WORKTREE_PATH:-None}"
date_str="$(date +%F)"
timestamp="$(date -Iseconds)"
branch_name="$(git branch --show-current 2>/dev/null || printf 'unknown')"
minutes_dir="docs/minutes"
template="${minutes_dir}/template.md"
target="${minutes_dir}/${date_str}-${topic}-${tool}.md"

if [[ -e "$target" ]]; then
  echo "file already exists: $target" >&2
  exit 1
fi

mkdir -p "$minutes_dir"
if [[ ! -f "$template" ]]; then
  echo "minutes template not found: $template" >&2
  exit 1
fi

cp "$template" "$target"

escape_replacement() {
  printf '%s' "$1" | sed -e 's/[&|]/\\&/g'
}

replace_literal() {
  local needle="$1"
  local value="$2"
  local escaped

  escaped="$(escape_replacement "$value")"
  sed -i.bak "s|${needle}|${escaped}|g" "$target"
  rm -f "${target}.bak"
}

replace_literal "title: title" "title: ${title}"
replace_literal "meeting_name: title" "meeting_name: ${title}"
replace_literal "topic: short-topic" "topic: ${topic}"
replace_literal "date: YYYY-MM-DD" "date: ${date_str}"
replace_literal "timestamp: YYYY-MM-DDTHH:MM:SS+09:00" "timestamp: ${timestamp}"
replace_literal "tool: Claude-Code / Other" "tool: ${tool}"
replace_literal "meeting_type: general / issue-triage / report-qa" "meeting_type: ${meeting_type}"
replace_literal "participants: User, AI tools" "participants: ${participants}"
replace_literal "objective: Write the one-sentence objective of the meeting" "objective: ${objective}"
replace_literal "constraints: None" "constraints: ${constraints}"
replace_literal "started_from_branch: main" "started_from_branch: ${started_from_branch}"
replace_literal "started_from_path: /absolute/path/to/repo" "started_from_path: ${started_from_path}"
replace_literal "branch: yyyy-mm-dd-hh-mm-discuss_topic" "branch: ${branch_name}"
replace_literal "workspace_mode: branch-only / worktree" "workspace_mode: ${workspace_mode}"
replace_literal "worktree_path: None / /absolute/path/to/worktree" "worktree_path: ${worktree_path}"
replace_literal "status: draft / final" "status: ${status}"
replace_literal "# Meeting: title" "# Meeting: ${title}"

echo "$target"
