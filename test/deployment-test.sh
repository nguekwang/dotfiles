. "$(dirname "$0")/base-test.sh"

list_step_read() {
    awk -v name_list="$1" '
    index($0, name_list "=\"") == 1 { enum_in = 1; sub(/^[^=]*=/, "") }
    enum_in { print; if (/"$/) exit }' "$path_setup" | tr -d '"\\' | tr -s ' \t' '\n\n' | sed '/^$/d'
}

list_source_read() {
    awk '
    /^[[:space:]]*for [a-z0-9_]+ in .*; do$/ {
        name_var = $2
        list_item = $0
        sub(/^.* in /, "", list_item)
        sub(/; do$/, "", list_item)
        next
    }
    /^[[:space:]]*done$/ { name_var = ""; next }
    $1 == "link" && ($2 == "user" || $2 == "sudo") {
        path_src = $3
        gsub(/"/, "", path_src)
        index_var = name_var == "" ? 0 : index(path_src, "$" name_var)
        if (index_var == 0) { print path_src; next }
        count_item = split(list_item, list_each, " ")
        for (i = 1; i <= count_item; i++)
            print substr(path_src, 1, index_var - 1) list_each[i] substr(path_src, index_var + length(name_var) + 1)
    }' "$path_setup"
}

sh -n "$path_setup" || fail "setup.sh parses as POSIX sh"
pass "setup.sh parses as POSIX sh"

for name_fn in link probe_path; do
    grep -q "^$name_fn() {" "$path_setup" || fail "setup.sh defines $name_fn"
done
pass "setup.sh defines link and probe_path"

list_step="$(list_step_read list_step_label | sed 's|^.*/||')"
[ -n "$list_step" ] || fail "list_step_label is readable"
for name_step in $list_step; do
    grep -q "^setup_$name_step() {" "$path_setup" || fail "step $name_step has a setup_$name_step function"
done
pass "every step in list_step_label has a setup_ function ($(printf '%s\n' "$list_step" | wc -l | tr -d ' ') steps)"

for name_list in list_step_sudo list_step_interactive list_step_irreversible; do
    for name_step in $(list_step_read "$name_list"); do
        printf '%s\n' "$list_step" | grep -qxF "$name_step" || fail "$name_list names only steps in list_step_label" "unknown: $name_step"
    done
done
pass "list_step_sudo, list_step_interactive and list_step_irreversible name only known steps"

for name_label in $(list_step_read list_step_label); do
    grep -qF "| \`$name_label\` |" "$path_root/CLAUDE.md" || fail "every step is in the CLAUDE.md steps table" "missing: $name_label"
done
pass "every step is in the CLAUDE.md steps table"

list_source="$(list_source_read)"
[ -n "$list_source" ] || fail "link calls are readable"
for path_source in $list_source; do
    [ -e "$path_root/$path_source" ] || fail "link source exists: $path_source"
done
pass "every link source exists ($(printf '%s\n' "$list_source" | wc -l | tr -d ' ') paths)"

list_missing=""
for path_file in $(cd "$path_root" && find home etc -type f | sort); do
    enum_wired=no
    for path_source in $list_source; do
        case "$path_file" in "$path_source"|"$path_source"/*) enum_wired=yes; break ;; esac
    done
    case "$enum_wired" in no) list_missing="$list_missing $path_file" ;; esac
done
[ -z "$list_missing" ] || fail "every file under home/ and etc/ is linked by setup.sh" "unlinked:$list_missing"
pass "every file under home/ and etc/ is linked by setup.sh"
