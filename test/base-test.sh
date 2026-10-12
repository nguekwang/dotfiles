# Sourced by every test/*-test.sh; never run directly.
# Protocol, as in omarchy's test/shell.d/base-test.sh: `ok - <what>` on
# success, `not ok - <what>` on stderr and exit 1 at the first failure, so no
# later assertion reports against state an earlier failure invalidated.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT
pass() { printf 'ok - %s\n' "$1"; }
skip() { printf 'ok - %s # SKIP\n' "$1"; }
fail() {
    [ -n "${2:-}" ] && printf '%s\n' "$2" >&2
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}
