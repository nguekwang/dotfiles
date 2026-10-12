. "$(dirname "$0")/base-test.sh"
path_setup="$ROOT/setup.sh"
sh -n "$path_setup" || fail "setup.sh parses as sh"
pass "setup.sh parses as sh"
grep -q '^link() {' "$path_setup" || fail "setup.sh defines link"
pass "setup.sh defines link"

list_step="$(sed -n '/^list_step_label="/,/"$/p' "$path_setup" |
    tr ' \\"' '\n\n\n' | sed -n 's|^[a-z]*/\([a-z_]*\)$|\1|p')"
[ -n "$list_step" ] || fail "list_step_label is readable"
for name_step in $list_step; do
    grep -q "^setup_$name_step() {" "$path_setup" ||
        fail "step $name_step has a setup_ function"
done
pass "every declared step has a setup_ function"

list_source="$(sed -n 's/^[[:space:]]*link \(user\|sudo\) \([^ "$]*\) .*/\2/p' "$path_setup")"
[ -n "$list_source" ] || fail "link sources are readable"
for path_source in $list_source; do
    [ -e "$ROOT/$path_source" ] || fail "link source exists: $path_source"
done
pass "every literal link source exists"

list_conf="$(sed -n 's/^[[:space:]]*for name_fcitx5_conf in \(.*\); do$/\1/p' "$path_setup")"
[ -n "$list_conf" ] || fail "fcitx5 loop is readable"
grep -Fq 'link user "home/fcitx5/$name_fcitx5_conf.conf"' "$path_setup" ||
    fail "fcitx5 loop wires its sources"
for name_conf in $list_conf; do
    [ -e "$ROOT/home/fcitx5/$name_conf.conf" ] || fail "fcitx5 source exists: $name_conf"
done
pass "every dynamic fcitx5 source exists"

path_tmp="$(mktemp -d)"
trap 'rm -rf "$path_tmp"' 0
(cd "$ROOT" && find home etc -type f | sort) >"$path_tmp/files" || fail "deployment roots are readable"
while IFS= read -r path_file; do
    enum_wired=no
    for path_source in $list_source; do
        case "$path_file" in
            "$path_source"|"$path_source"/*) enum_wired=yes; break ;;
        esac
    done
    if [ "$enum_wired" = no ]; then
        for name_conf in $list_conf; do
            [ "$path_file" != "home/fcitx5/$name_conf.conf" ] || enum_wired=yes
        done
    fi
    [ "$enum_wired" = no ] || continue
    cut -f1 "$ROOT/test/unwired-files.txt" | grep -qxF "$path_file" && continue
    fail "deployment source is wired or exempt: $path_file"
done <"$path_tmp/files"
pass "every deployment source is wired or explicitly exempt"

while IFS="$(printf '\t')" read -r path_file text_reason; do
    case "$path_file" in ''|'#'*) continue ;; esac
    [ -f "$ROOT/$path_file" ] || fail "unwired entry exists: $path_file"
    [ -n "$text_reason" ] || fail "unwired entry has a reason: $path_file"
done <"$ROOT/test/unwired-files.txt"
pass "every exemption exists and carries a reason"
