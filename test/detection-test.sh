. "$(dirname "$0")/base-test.sh"
path_tmp="$(mktemp -d)"
trap 'rm -rf "$path_tmp"' 0
mkdir -p "$path_tmp/test"
cp "$ROOT/setup.sh" "$path_tmp/setup.sh"
cp -R "$ROOT/home" "$ROOT/etc" "$path_tmp/"
cp "$ROOT/test/base-test.sh" "$ROOT/test/deployment-test.sh" "$ROOT/test/unwired-files.txt" "$path_tmp/test/"

rm "$path_tmp/home/.gitmessage"
if sh "$path_tmp/test/deployment-test.sh" >"$path_tmp/result" 2>&1; then
    fail "a missing link source fails"
fi
grep -q 'link source exists: home/.gitmessage' "$path_tmp/result" || fail "missing source diagnosis"
cp "$ROOT/home/.gitmessage" "$path_tmp/home/.gitmessage"
pass "a missing link source fails with a diagnosis"

printf 'fixture\n' >"$path_tmp/home/unwired-fixture.conf"
if sh "$path_tmp/test/deployment-test.sh" >"$path_tmp/result" 2>&1; then
    fail "an unwired file fails"
fi
grep -q 'wired or exempt: home/unwired-fixture.conf' "$path_tmp/result" || fail "unwired file diagnosis"
rm "$path_tmp/home/unwired-fixture.conf"
pass "an unwired file fails with a diagnosis"

sed 's/^setup_shell() {/retired_shell() {/' "$ROOT/setup.sh" >"$path_tmp/setup.sh"
if sh "$path_tmp/test/deployment-test.sh" >"$path_tmp/result" 2>&1; then
    fail "a missing step function fails"
fi
grep -q 'step shell has a setup_ function' "$path_tmp/result" || fail "missing step diagnosis"
pass "a missing step function fails with a diagnosis"
