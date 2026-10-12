# setup.sh is the only path from this repository to a machine (see the
# dotfile-deployment skill). These checks keep that path intact.
. "$(dirname "$0")/base-test.sh"
path_setup="$ROOT/setup.sh"

sh -n "$path_setup" || fail "setup.sh parses as POSIX sh"
pass "setup.sh parses as POSIX sh"

for name_fn in link_userconfig link_sysconfig backup_userconfig setup_migrate; do
    grep -q "^$name_fn() {" "$path_setup" || fail "setup.sh defines $name_fn"
done
pass "setup.sh defines its link and migrate helpers"

# Every step in list_step_spec has a setup_<step> function. An entry is
# `<category>/<step>:<devices>`, so the category is dropped before the lookup:
# the function is named after the step, and the category says only where the
# step's effect lands.
list_step="$(sed -n '/^list_step_spec="/,/"$/p' "$path_setup" |
    tr ' \\"' '\n\n\n' | sed -n 's/^[a-z]*\/\([a-z_]*\):[a-z]*$/\1/p')"
[ -n "$list_step" ] || fail "list_step_spec is readable"
for name_step in $list_step; do
    grep -q "^setup_$name_step() {" "$path_setup" ||
        fail "step $name_step has a setup_$name_step function"
done
pass "every step in list_step_spec has a setup_ function"

# Every literal source path passed to a link helper exists in the checkout.
list_source="$(sed -n 's/^[[:space:]]*\(linux:yes)[[:space:]]*\)\{0,1\}link_\(user\|sys\)config \([^ "$]*\) .*/\3/p' "$path_setup")"
[ -n "$list_source" ] || fail "link calls are readable"
for path_source in $list_source; do
    [ -e "$ROOT/$path_source" ] || fail "link source exists: $path_source"
done
pass "every link source exists ($(printf '%s\n' "$list_source" | wc -l | tr -d ' ') paths)"

# Every file under user/ and etc/ is deployed by setup.sh, directly or through
# the fcitx5 loop, unless listed in unwired-files.txt with a reason.
path_unwired="$ROOT/test/unwired-files.txt"
list_missing=""
for path_file in $(cd "$ROOT" && find user etc -type f | sort); do
    grep -q "[[:space:]]$path_file[[:space:]]" "$path_setup" && continue
    case "$path_file" in
        user/fcitx5/*.conf)
            name_conf="$(basename "$path_file" .conf)"
            sed -n '/for name_fcitx5_conf in/p' "$path_setup" | grep -qw "$name_conf" && continue
            ;;
    esac
    cut -f1 "$path_unwired" | grep -qxF "$path_file" && continue
    list_missing="$list_missing $path_file"
done
[ -z "$list_missing" ] || fail "every dotfile is wired into setup.sh or listed as unwired" "unwired:$list_missing"
pass "every dotfile is wired into setup.sh or listed as unwired"

# The unwired list names only files that exist and gives each a reason.
while IFS="$(printf '\t')" read -r path_file text_reason; do
    case "$path_file" in ''|'#'*) continue ;; esac
    [ -e "$ROOT/$path_file" ] || fail "unwired entry exists: $path_file"
    [ -n "$text_reason" ] || fail "unwired entry has a reason: $path_file"
done < "$path_unwired"
pass "every unwired entry exists and carries a reason"
