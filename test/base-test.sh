path_root="$(cd "$(dirname "$0")/.." && pwd)"
path_setup="$path_root/setup.sh"
pass() { printf 'ok - %s\n' "$1"; }
fail() {
    [ -n "${2:-}" ] && printf '%s\n' "$2" >&2
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}
