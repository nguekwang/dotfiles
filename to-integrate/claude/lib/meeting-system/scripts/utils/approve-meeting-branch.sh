#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
usage: approve-meeting-branch.sh [<meeting-branch>] [--base-branch <branch>] [--body <text>] [--minutes-file <path>]

Compatibility wrapper around review-meeting-branch.sh for approval-only usage.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

exec "$ROOT_DIR/scripts/utils/review-meeting-branch.sh" "$@" --decision approve
