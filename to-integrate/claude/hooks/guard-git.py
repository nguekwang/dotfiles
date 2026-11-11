#!/usr/bin/env python3
"""PreToolUse(Bash): the version-control rules on branches and worktrees.

Force pushes and deletions of `main` are not checked here; the first is the
"Never force-push" bullet of the `rules-version-control` skill, the second is
GitHub's branch protection. This file makes two checks, and one of them behaves
differently from every other hook here: it rewrites the command instead of
refusing it.

| Check | Strength | Rule |
| --- | --- | --- |
| a new branch named outside the permitted form | rewrite | the name is normalised, not rejected |
| removing a worktree that has uncommitted changes | warn | whether the changes matter is a judgement |

Why the branch check rewrites. A branch name in this repository is not read by a
person: it is a key that tells the tooling when the branch was opened and what it
is for. Asking the operator to spell that key correctly puts the burden in the
wrong place, and a hook that refuses a misspelling makes it worse, because the
work stops over punctuation. So the hook takes whatever name was asked for,
derives the conforming name from it, and edits the command through
`updatedInput`. The operator states the purpose; the hook supplies the spelling.

Every branch, meeting branches and rule-skill edits included, takes the one
permitted form, per the `files-and-repository` skill's verb-object rule applied
to branches instead of files:

| Form | Meaning |
| --- | --- |
| `main` | the integration branch; never rewritten |
| `yyyy-mm-dd-hh-mm-<verb>` | a branch for one bare action, no object needed (e.g. `refactor`) |
| `yyyy-mm-dd-hh-mm-<verb>_<objective-noun-group>` | a branch for an action with an object (e.g. `fix_typo`, `discuss_pricing-model`) |

There is no longer a reserved prefix for "this is a meeting" or "this is a
rule-skill edit": which flow a branch belongs to is a fact about what verb and
object it names, not a namespace it lives under, and nothing needs to recognise
a branch's flow from its name at all.

Deriving a conforming name needs no semantic verb detection, because an operator
already phrases a branch topic verb-first ("fix-typo", "add-x"): slugify the
given name the same way `slug()` below does, split it on its first hyphen into
verb and object, join them with `_`, and prepend the branch's creation moment as
`yyyy-mm-dd-hh-mm`. A name with no hyphen becomes a bare verb.

Test (the rewrite and the worktree warning): .claude/lib/hook-tests/test-guard-git.py
"""

import json
import re
import sys
from datetime import datetime

from hooklib import payload, segments, strip_wrappers, tag, warn

INTEGRATION = "main"
BRANCH_FORM = re.compile(
    r"^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-[a-z][a-z0-9]*(_[a-z0-9]+(-[a-z0-9]+)*)?$"
)
# Flags that put `git branch` into a mode other than creation. Any of them means
# the operand names a branch that already exists, so its spelling is a fact and
# must not be rewritten.
BRANCH_MODE_FLAGS = frozenset([
    "-d", "-D", "--delete",
    "-m", "-M", "--move",
    "-c", "-C", "--copy",
    "-l", "--list", "-a", "--all", "-r", "--remotes", "-v", "-vv", "--verbose",
    "-u", "--unset-upstream", "--edit-description", "--show-current",
])
# Branch names that are not topic branches and are exempt from the form rule.
EXEMPT_BRANCHES = {INTEGRATION}


def slug(raw):
    """The topic slug, by the same rule as scripts/utils/start-meeting.sh."""
    out = re.sub(r"[^a-z0-9]+", "-", (raw or "").lower()).strip("-")
    return re.sub(r"-{2,}", "-", out)


def conforming(name):
    return name in EXEMPT_BRANCHES or bool(BRANCH_FORM.match(name))


def derive(name, now=None):
    """The conforming branch name this one becomes, or None when it already is.

    No prefix decides a flow anymore; every name gets the same treatment. The
    first word of the slug is taken as the verb and everything after its first
    hyphen as the object, because an operator already phrases a branch topic
    verb-first ("fix-typo", "add-x"). Detecting the verb is therefore spelling,
    not semantics, which is this function's business either way.
    """
    if conforming(name):
        return None
    now = now or datetime.now()
    stamp = now.strftime("%Y-%m-%d-%H-%M")
    # Drop a leading date the operator already typed, in any separator style, so
    # the date is not written twice.
    rest = re.sub(r"^\d{4}[-_/]?\d{2}[-_/]?\d{2}[-_]?", "", name)
    whole = slug(rest) or "untitled"
    verb, _, object_ = whole.partition("-")
    return f"{stamp}-{verb}_{object_}" if object_ else f"{stamp}-{verb}"
# Global git options that consume the next token, so a subcommand is not mistaken
# for one of their values.
VALUED_GLOBALS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}


def git_argv(argv):
    """(subcommand, remaining args) for a git invocation, or (None, [])."""
    if not argv or argv[0] != "git":
        return None, []
    rest = argv[1:]
    while rest:
        if rest[0] in VALUED_GLOBALS:
            rest = rest[2:]
        elif rest[0].startswith("-"):
            rest = rest[1:]
        else:
            break
    if not rest:
        return None, []
    return rest[0], rest[1:]


def branch_operand(argv):
    """(the branch name a command creates, its index in argv), or (None, -1).

    Only creation is considered. Checking out a branch that already exists must
    not be rewritten: the name is then a fact about the repository, and editing it
    would point the command at a branch that does not exist.
    """
    sub, rest = git_argv(argv)
    flag = None
    if sub == "checkout" and "-b" in rest:
        flag = "-b"
    elif sub == "checkout" and "-B" in rest:
        flag = "-B"
    elif sub == "switch" and ("-c" in rest or "--create" in rest):
        flag = "-c" if "-c" in rest else "--create"
    elif sub == "branch":
        # `git branch` creates only in its bare form. Every other mode takes an
        # existing branch name, and rewriting that name would point the command at
        # a branch that does not exist: `-d 2026-09-26-14-30-fix_feature-old`
        # deletes nothing and reports failure, while the branch the operator
        # meant stays.
        if any(a in BRANCH_MODE_FLAGS or a.startswith("--set-upstream")
               or a.startswith("--contains") or a.startswith("--merged")
               or a.startswith("--no-merged") or a.startswith("--points-at")
               for a in rest):
            return None, -1
        operands = [a for a in rest if not a.startswith("-")]
        if not operands:
            return None, -1
        return operands[0], argv.index(operands[0])
    if flag is None:
        return None, -1
    i = rest.index(flag)
    if i + 1 >= len(rest):
        return None, -1
    name = rest[i + 1]
    return name, argv.index(name)


def rewrite_branch(data, argv):
    """Edit the command so the new branch carries a conforming name.

    Returns the decision object, or None when nothing needs changing. The edit is
    a single token substitution in the original command string rather than a
    rebuild from argv, so quoting, spacing, and everything else the operator typed
    survive untouched.
    """
    name, _ = branch_operand(argv)
    if not name:
        return None
    new = derive(name)
    if not new:
        return None

    command = (data.get("tool_input") or {}).get("command", "") or ""
    # Substitute the token, not every occurrence of the substring: a name that is
    # also a path component or part of a message must not be caught.
    pattern = re.compile(rf"(?<![\w/.-]){re.escape(name)}(?![\w/.-])")
    updated, count = pattern.subn(new, command)
    if count == 0:
        return None

    tool_input = dict(data.get("tool_input") or {})
    tool_input["command"] = updated
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": tag(
                f"Branch name normalised: `{name}` to `{new}`. A branch name here is "
                "a key the tooling reads, not prose for a person, so the hook "
                "supplies the spelling and the operator supplies the purpose. The "
                "permitted form is `yyyy-mm-dd-hh-mm-<verb>` or "
                "`yyyy-mm-dd-hh-mm-<verb>_<objective-noun-group>`, for every branch."
            ),
            "updatedInput": tool_input,
        }
    }


def check_worktree_remove(argv):
    sub, rest = git_argv(argv)
    if sub != "worktree" or not rest or rest[0] != "remove":
        return None
    if "--force" in rest or "-f" in rest:
        return (
            "`git worktree remove --force` discards uncommitted changes in that "
            "worktree without asking. Remove a worktree only when it is clean; "
            "check `git -C <worktree> status --porcelain` first and keep the "
            "force flag for a worktree you have confirmed empty."
        )
    return None


def main():
    data = payload()
    if data is None:
        return 0
    command = (data.get("tool_input") or {}).get("command", "") or ""

    findings = []
    for raw in segments(command):
        argv = strip_wrappers(raw)
        if not argv:
            continue
        soft = check_worktree_remove(argv)
        if soft:
            findings.append(soft)

    # Then the rewrite. Only the first branch creation in the command is edited:
    # rewriting two names in one command would need two timestamps and the second
    # would silently collide with the first.
    for raw in segments(command):
        argv = strip_wrappers(raw)
        if not argv:
            continue
        decision = rewrite_branch(data, argv)
        if decision:
            json.dump(decision, sys.stdout)
            return 0

    warn("PreToolUse", findings, "Version-control findings for this command.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
