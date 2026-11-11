#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/meeting-branch.sh"

usage() {
  cat <<'EOF'
usage: start-meeting.sh [--dry-run] [--parallel] [--model <model>] [--type <meeting-type>] [<meeting-name> <purpose> [constraints] [participants]]

Creates a meeting branch and minutes draft, then starts an interactive AI meeting session with a structured kickoff prompt.
If arguments are omitted, a wizard prompts for the missing values.

Supported models:
  - claude

Supported meeting types:
  - general
  - issue-triage
  - report-qa

Participants can be:
  - all
  - a comma-separated list of agent ids such as dev,research
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENTS_DIR="$ROOT_DIR/agents"

MODEL_IDS=("claude")
MODEL_LABELS=("claude code")
MEETING_TYPE_IDS=("general" "issue-triage" "report-qa")
MEETING_TYPE_LABELS=(
  "general"
  "issue triage: recurring review to triage and work through open GitHub issues"
  "report qa: user asks questions and AI agents answer to improve report understanding"
)

meeting_prompt_label() {
  local type="$1"
  local field="$2"

  case "$type:$field" in
    general:meeting_name)
      printf '%s' 'Meeting name?'
      ;;
    general:purpose)
      printf '%s' 'Meeting purpose?'
      ;;
    general:constraints)
      printf '%s' 'Meeting constraints?'
      ;;
    issue-triage:meeting_name)
      printf '%s' 'Issue triage meeting name?'
      ;;
    issue-triage:purpose)
      printf '%s' 'Issue triage scope?'
      ;;
    issue-triage:constraints)
      printf '%s' 'Issue triage constraints?'
      ;;
    report-qa:meeting_name)
      printf '%s' 'Report Q&A meeting name?'
      ;;
    report-qa:purpose)
      printf '%s' 'Primary user question or report objective?'
      ;;
    report-qa:constraints)
      printf '%s' 'Report Q&A constraints?'
      ;;
    *)
      printf 'error: unknown prompt label for %s/%s\n' "$type" "$field" >&2
      exit 1
      ;;
  esac
}

meeting_prompt_default() {
  local type="$1"
  local field="$2"

  case "$type:$field" in
    general:meeting_name|general:purpose)
      printf '%s' ''
      ;;
    general:constraints)
      printf '%s' 'None'
      ;;
    issue-triage:meeting_name)
      printf '%s' 'issue-triage'
      ;;
    issue-triage:purpose)
      printf '%s' 'Review and work through open GitHub issues'
      ;;
    issue-triage:constraints)
      printf '%s' 'None'
      ;;
    report-qa:meeting_name)
      printf '%s' 'report-qa'
      ;;
    report-qa:purpose)
      printf '%s' 'Answer user questions to improve report understanding'
      ;;
    report-qa:constraints)
      printf '%s' 'None'
      ;;
    *)
      printf 'error: unknown prompt default for %s/%s\n' "$type" "$field" >&2
      exit 1
      ;;
  esac
}

prompt_for_value() {
  local var_name="$1"
  local label="$2"
  local default_value="${3:-}"
  local allow_empty="${4:-0}"
  local answer

  if [[ ! -t 0 ]]; then
    printf 'error: missing required value for %s and no interactive terminal is available\n' "$label" >&2
    exit 1
  fi

  while true; do
    if [[ -n "$default_value" ]]; then
      read -r -p "$label [$default_value]: " answer
      answer="${answer:-$default_value}"
    else
      read -r -p "$label: " answer
    fi

    if [[ -n "$answer" || "$allow_empty" == "1" ]]; then
      printf -v "$var_name" '%s' "$answer"
      return
    fi

    printf '%s is required.\n' "$label" >&2
  done
}

clear_lines() {
  local count="$1"
  local i

  for ((i = 0; i < count; i++)); do
    printf '\033[1A\033[2K\r'
  done
}

select_single_option() {
  local prompt="$1"
  local options_name="$2"
  local values_name="$3"
  local selected_name="$4"
  local -n options_ref="$options_name"
  local -n values_ref="$values_name"
  local answer
  local count="${#options_ref[@]}"
  local selected=0
  local lines=$((count + 2))
  local i key

  if [[ ! -t 0 ]]; then
    printf 'error: %s requires an interactive terminal\n' "$prompt" >&2
    exit 1
  fi

  while true; do
    printf '%s\n' "$prompt" >&2
    printf 'Use ↑/↓ and Enter.\n' >&2
    for ((i = 0; i < count; i++)); do
      if (( i == selected )); then
        printf '› %s\n' "${options_ref[$i]}" >&2
      else
        printf '  %s\n' "${options_ref[$i]}" >&2
      fi
    done

    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 key || true
      case "$key" in
        "[A") selected=$(((selected - 1 + count) % count)) ;;
        "[B") selected=$(((selected + 1) % count)) ;;
      esac
    elif [[ "$key" == "" ]]; then
      printf -v "$selected_name" '%s' "${values_ref[$selected]}"
      clear_lines "$lines"
      printf '%s %s\n' "$prompt" "${options_ref[$selected]}" >&2
      return
    fi

    clear_lines "$lines"
  done
}

join_selected_participants() {
  local output_name="$1"
  shift
  local items=("$@")
  local joined=""
  local item

  for item in "${items[@]}"; do
    if [[ -z "$joined" ]]; then
      joined="$item"
    else
      joined="$joined,$item"
    fi
  done

  printf -v "$output_name" '%s' "$joined"
}

load_agent_options() {
  local agent_file
  local rel

  PARTICIPANT_LABELS=("all")
  PARTICIPANT_VALUES=("all")

  while IFS= read -r agent_file; do
    rel="${agent_file#$AGENTS_DIR/}"
    rel="${rel%/CLAUDE.md}"
    PARTICIPANT_LABELS+=("$rel")
    PARTICIPANT_VALUES+=("$rel")
  done < <(grep -rl --include=CLAUDE.md -x '## Role' "$AGENTS_DIR" | sort)
}

parse_participants() {
  local input="$1"
  local output_name="$2"
  local known raw normalized
  local -a parsed=()
  local -a requested=()
  local item

  if [[ -z "$input" || "$input" == "all" ]]; then
    printf -v "$output_name" 'all'
    return
  fi

  IFS=',' read -r -a requested <<< "$input"
  for raw in "${requested[@]}"; do
    normalized="${raw#"${raw%%[![:space:]]*}"}"
    normalized="${normalized%"${normalized##*[![:space:]]}"}"
    [[ -z "$normalized" ]] && continue

    if [[ "$normalized" == "all" ]]; then
      printf -v "$output_name" 'all'
      return
    fi

    known=0
    for item in "${PARTICIPANT_VALUES[@]:1}"; do
      if [[ "$item" == "$normalized" ]]; then
        known=1
        parsed+=("$normalized")
        break
      fi
    done

    if [[ $known -eq 0 ]]; then
      printf 'error: unknown participant "%s"\n' "$normalized" >&2
      exit 1
    fi
  done

  if [[ ${#parsed[@]} -eq 0 ]]; then
    printf -v "$output_name" 'all'
    return
  fi

  join_selected_participants "$output_name" "${parsed[@]}"
}

select_participants() {
  local selected=0
  local count="${#PARTICIPANT_LABELS[@]}"
  local key
  local i
  local lines=$((count + 2))
  local -a chosen=()

  chosen=("all")

  if [[ ! -t 0 ]]; then
    printf 'error: Who should participate? requires an interactive terminal\n' >&2
    exit 1
  fi

  while true; do
    printf 'Who should participate?\n' >&2
    printf 'Use ↑/↓, Space to toggle, Enter to confirm.\n' >&2
    for ((i = 0; i < count; i++)); do
      local marker="[ ]"
      local value="${PARTICIPANT_VALUES[$i]}"
      local prefix=" "

      if [[ " ${chosen[*]} " == *" $value "* ]]; then
        marker="[x]"
      fi
      if (( i == selected )); then
        prefix='›'
      fi
      printf '%s %s %s\n' "$prefix" "$marker" "${PARTICIPANT_LABELS[$i]}" >&2
    done

    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 key || true
      case "$key" in
        "[A") selected=$(((selected - 1 + count) % count)) ;;
        "[B") selected=$(((selected + 1) % count)) ;;
      esac
    elif [[ "$key" == " " ]]; then
      local current="${PARTICIPANT_VALUES[$selected]}"
      local exists=0
      local -a next=()

      if [[ "$current" == "all" ]]; then
        chosen=("all")
      else
        for i in "${!chosen[@]}"; do
          if [[ "${chosen[$i]}" == "$current" ]]; then
            exists=1
          else
            next+=("${chosen[$i]}")
          fi
        done

        if [[ $exists -eq 1 ]]; then
          chosen=("${next[@]}")
        else
          chosen=("${next[@]}")
          chosen+=("$current")
        fi

        next=()
        for i in "${!chosen[@]}"; do
          if [[ "${chosen[$i]}" != "all" ]]; then
            next+=("${chosen[$i]}")
          fi
        done
        chosen=("${next[@]}")

        if [[ ${#chosen[@]} -eq 0 ]]; then
          chosen=("all")
        fi
      fi
    elif [[ "$key" == "" ]]; then
      join_selected_participants participants "${chosen[@]}"
      clear_lines "$lines"
      printf 'Who should participate? %s\n' "$participants" >&2
      return
    fi

    clear_lines "$lines"
  done
}

slugify_topic() {
  local raw="$1"
  printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

build_prompt() {
  local type_label
  type_label="$(meeting_type_display_name "$meeting_type")"

  cat <<EOF
We are now working in meeting mode.

Meeting Name: ${meeting_name}
Meeting Type: ${type_label}
Purpose: ${purpose}
Constraints: ${constraints}
Participants: ${participants}
Meeting Branch: ${meeting_branch}
Minutes Draft: ${minutes_file}

Working Rules:
- Speak from explicit roles.
- Prioritize the perspectives of participating agents, and use PM / Dev / Ops / Reviewer as supporting lenses when needed.
- Adjust the depth and output shape to fit the meeting type.
- In \`report-qa\`, the default format is that the user asks questions and participating agents answer.
- In \`report-qa\`, avoid flooding the user with proactive question lists; prioritize answering the user's question first.
- Maintain running notes during the meeting and show only diffs when updating them.
- Move off-topic threads to the Parking Lot and state the Current Focus before returning to the main topic.
- Always end with Decisions, Open Questions, and Action Items.
- After the meeting, keep Action Items recorded in the minutes file, then commit the minutes on the meeting branch and, once merging is authorized, integrate it into \`main\` per the \`rules-version-control\` skill.
- Format the final output as clean Markdown.
EOF
}

meeting_type_display_name() {
  case "$1" in
    general)
      printf '%s' 'general'
      ;;
    issue-triage)
      printf '%s' 'issue-triage (recurring review to triage and work through open GitHub issues)'
      ;;
    report-qa)
      printf '%s' 'report-qa (user asks questions and AI agents answer to improve report understanding)'
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

launch_meeting() {
  case "$model" in
    claude)
      cd "$meeting_cwd"
      exec claude "$prompt"
      ;;
    *)
      printf 'error: unsupported model "%s"\n' "$model" >&2
      exit 1
      ;;
  esac
}

dry_run=0
parallel=0
model=""
meeting_type=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --parallel)
      parallel=1
      shift
      ;;
    --model)
      model="${2:-}"
      if [[ -z "$model" ]]; then
        usage >&2
        exit 1
      fi
      shift 2
      ;;
    --type)
      meeting_type="${2:-}"
      if [[ -z "$meeting_type" ]]; then
        usage >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -gt 4 ]]; then
  usage >&2
  exit 1
fi

load_agent_options

meeting_name="${1:-}"
purpose="${2:-}"
constraints="${3:-}"
participants="${4:-all}"

if [[ -n "$model" ]]; then
  case "$model" in
    claude) ;;
    *)
      printf 'error: unknown model "%s"\n' "$model" >&2
      exit 1
      ;;
  esac
fi

if [[ -n "$meeting_type" ]]; then
  case "$meeting_type" in
    general|issue-triage|report-qa) ;;
    *)
      printf 'error: unknown meeting type "%s"\n' "$meeting_type" >&2
      exit 1
      ;;
  esac
fi

if [[ -t 0 ]]; then
  printf 'Meeting setup wizard\n' >&2
  if [[ -z "$model" ]]; then
    select_single_option "Which model?" MODEL_LABELS MODEL_IDS model
  fi
  if [[ -z "$meeting_type" ]]; then
    select_single_option "What type of meeting?" MEETING_TYPE_LABELS MEETING_TYPE_IDS meeting_type
  fi
  meeting_name_label="$(meeting_prompt_label "$meeting_type" meeting_name)"
  purpose_label="$(meeting_prompt_label "$meeting_type" purpose)"
  constraints_label="$(meeting_prompt_label "$meeting_type" constraints)"
  meeting_name_default="$(meeting_prompt_default "$meeting_type" meeting_name)"
  purpose_default="$(meeting_prompt_default "$meeting_type" purpose)"
  constraints_default="$(meeting_prompt_default "$meeting_type" constraints)"
  [[ -z "$meeting_name" ]] && prompt_for_value meeting_name "$meeting_name_label" "$meeting_name_default" 0
  [[ -z "$purpose" ]] && prompt_for_value purpose "$purpose_label" "$purpose_default" 0
  [[ -z "$constraints" ]] && prompt_for_value constraints "$constraints_label" "$constraints_default" 1
  if [[ -z "${4:-}" ]]; then
    select_participants
  fi
fi

constraints="${constraints:-None}"
meeting_type="${meeting_type:-general}"
parse_participants "$participants" participants

if [[ -z "$model" || -z "$meeting_type" || -z "$meeting_name" || -z "$purpose" ]]; then
  usage >&2
  exit 1
fi

topic="$(slugify_topic "$meeting_name")"
if [[ -z "$topic" ]]; then
  echo "failed to derive topic from meeting name: $meeting_name" >&2
  exit 1
fi

previous_branch="$(git branch --show-current)"
meeting_branch="$(meeting_branch_name "$topic")"
started_from_path="$(pwd)"
meeting_cwd="$started_from_path"
workspace_mode="branch-only"
worktree_path="None"

minutes_tool="Claude-Code"
minutes_file="docs/minutes/$(date +%F)-${topic}-${minutes_tool}.md"

if [[ $parallel -eq 1 ]]; then
  workspace_mode="worktree"
  worktree_path="$("$ROOT_DIR/scripts/utils/start-meeting-worktree.sh" "$topic" "${previous_branch:-main}")"
  meeting_cwd="$worktree_path"
  meeting_branch="$(git -C "$worktree_path" branch --show-current)"
fi

prompt="$(build_prompt)"

if [[ $dry_run -eq 1 ]]; then
  printf '%s\n' "$prompt"
  exit 0
fi

if [[ $parallel -eq 0 ]]; then
  "$ROOT_DIR/scripts/utils/start-meeting-branch.sh" "$topic"
  meeting_branch="$(git branch --show-current)"
fi

minutes_file="$(
  cd "$meeting_cwd"
  MEETING_STARTED_FROM_PATH="$started_from_path" \
  MEETING_WORKSPACE_MODE="$workspace_mode" \
  MEETING_WORKTREE_PATH="$worktree_path" \
    "$ROOT_DIR/scripts/utils/create-minutes.sh" \
    "$topic" "$minutes_tool" "$meeting_name" "$purpose" "$meeting_type" "$constraints" "$participants" "${previous_branch:-main}"
)"
prompt="$(build_prompt)"

launch_meeting
