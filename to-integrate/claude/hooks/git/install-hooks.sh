#!/bin/sh
# Install git's hooks for this clone into <git common dir>/hooks, each as it is in
# HEAD (or, before HEAD carries it, as staged), and clear core.hooksPath, so git
# uses that shared hooks directory for every branch and worktree:
#   guard-pre-rebase -> pre-rebase    history is never rewritten
# It also removes the copies of the hooks retired on 2026-10-17 (commit-msg,
# pre-push, reference-transaction) that an earlier run installed, recognised by
# the header this script's hooks carry, so a clone made before the retirement
# stops running them; a hook the user installed by other means is left alone.
# The first SessionStart hook in .claude/settings.json runs this at every session
# start; run it by hand after a commit changes the hook mid-session.
set -eu
top=$(git rev-parse --show-toplevel)
common=$(cd "$top" && cd "$(git rev-parse --git-common-dir)" && pwd)
git -C "$top" config --unset-all core.hooksPath 2>/dev/null || true
mkdir -p "$common/hooks"
for name in commit-msg pre-push reference-transaction; do
    dest=$common/hooks/$name
    [ -f "$dest" ] || continue
    if head -n 3 "$dest" | grep -q "by install-hooks.sh"; then
        rm -f "$dest"
        echo "Removed $dest (retired 2026-10-17)"
    fi
done
for pair in guard-pre-rebase:pre-rebase; do
    path=.claude/hooks/git/${pair%%:*}
    dest=$common/hooks/${pair#*:}
    git -C "$top" show "HEAD:$path" > "$dest.tmp" 2>/dev/null \
        || git -C "$top" show ":$path" > "$dest.tmp"
    chmod 755 "$dest.tmp"
    mv "$dest.tmp" "$dest"
    echo "Installed $dest"
done
