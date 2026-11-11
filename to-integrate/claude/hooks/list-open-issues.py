#!/usr/bin/env python3
"""SessionStart: list this repository's open GitHub issues as the resume point.

The accident this prevents: a follow-up is filed as an issue per the
`issue-tracking` skill, the session that filed it ends, and the next session
starts from the user's memory instead of from the issue. Printing the open
issues at start makes them the first thing the session sees.

The REST API is used through `gh api`, because GraphQL (what `gh issue list`
calls) is refused from cloud sessions while REST works everywhere. The slug is
read from the end of the `origin` remote URL, whatever its host, as the other
hooks do, so a proxied remote still resolves. Without `gh`, without
authentication, without a GitHub remote, or on any failure, the hook prints
nothing: it is a reminder, not an enforcement, and must never block a session
from starting. Pull requests are filtered out, since the issues endpoint
returns them too, and every page is fetched (`--paginate`), so the count is
the full total.
"""

import json
import re
import subprocess

from hooklib import context, git

JQ = '.[] | select(.pull_request | not) | [.number, .title, ((.body // "") | test("(?m)^[*][*]Waiting on:[*][*]"))]'
SLUG_RE = re.compile(r"[:/]([^/:]+)/([^/:]+?)(?:\.git)?/?$")


def slug():
    m = SLUG_RE.search(git("remote", "get-url", "origin").strip())
    return "%s/%s" % m.groups() if m else None


def open_issues(repo):
    try:
        out = subprocess.run(
            ["gh", "api", "--paginate", "--jq", JQ,
             "repos/%s/issues?state=open&per_page=100" % repo],
            capture_output=True, text=True, timeout=15, check=True,
        ).stdout
        return [json.loads(line) for line in out.splitlines() if line.strip()]
    except (OSError, subprocess.SubprocessError, ValueError):
        return None


def main():
    repo = slug()
    issues = open_issues(repo) if repo else None
    if issues is None:
        return
    if not issues:
        context("SessionStart", "issue tracking: %s has no open issues." % repo)
    lines = [
        "issue tracking: %d open issue(s) in %s. When asked to resume or continue, "
        "these are the work, per the issue-tracking skill. A body with a "
        "`**Waiting on:**` line waits on that trigger." % (len(issues), repo)
    ]
    for number, title, waiting in issues:
        lines.append("  #%d%s %s" % (number, " [waiting]" if waiting else "", title))
    context("SessionStart", "\n".join(lines))


if __name__ == "__main__":
    main()
