# Every migration follows the contract in migrations/CLAUDE.md, and the runner
# applies each once.
. "$(dirname "$0")/base-test.sh"
count=0
for path_migration in "$ROOT"/migrations/*.sh; do
    [ -f "$path_migration" ] || continue
    count=$((count + 1))
    name="$(basename "$path_migration")"
    printf '%s\n' "$name" | grep -qx '[0-9]\{10\}\.sh' || fail "$name is named <epoch>.sh"
    [ "$(stat -c %a "$path_migration")" = 644 ] || fail "$name has mode 0644"
    head -c 2 "$path_migration" | grep -q '^#!' && fail "$name has no shebang"
    sh -n "$path_migration" || fail "$name parses as POSIX sh"
done
[ "$count" -gt 0 ] || { skip "no migrations to check"; exit 0; }
pass "all $count migrations follow the naming, mode, shebang and syntax contract"

# Run setup_migrate twice against a scratch home: the first run applies and
# marks every migration, the second runs none.
path_tmp="$(mktemp -d)"
trap 'rm -rf "$path_tmp"' EXIT
(
    HOME="$path_tmp/home" XDG_STATE_HOME="$path_tmp/state" XDG_CONFIG_HOME="$path_tmp/home/.config"
    export HOME XDG_STATE_HOME XDG_CONFIG_HOME
    mkdir -p "$XDG_CONFIG_HOME/nvim"
    ln -s /nonexistent "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
    cd "$ROOT"
    eval "$(sed '/^status_start$/,$d' setup.sh)"
    enum_is_tty=no
    setup_migrate >"$path_tmp/first" 2>&1 || { cat "$path_tmp/first" >&2; exit 1; }
    [ ! -L "$XDG_CONFIG_HOME/nvim/lazy-lock.json" ] || exit 2
    setup_migrate >"$path_tmp/second" 2>&1 || exit 3
    grep -q 'migrate: [0-9]' "$path_tmp/second" && exit 4
    exit 0
) || fail "setup_migrate applies each migration once" "status $?"
# The directory under XDG_STATE_HOME is named after the repository, so it is
# read from setup.sh rather than written out again here: the two drifted apart
# when the repository was renamed.
name_state="$(sed -n 's|^path_state=.*/\([a-z-]*\)"$|\1|p' "$ROOT/setup.sh")"
[ -n "$name_state" ] || fail "setup.sh names its state directory"
[ "$(ls "$path_tmp/state/$name_state/migrations" | wc -l)" -eq "$count" ] ||
    fail "setup_migrate writes one marker per migration"
pass "setup_migrate applies each migration once and marks it"
