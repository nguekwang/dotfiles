#!/usr/bin/env python3
"""PreToolUse(Write|Edit|NotebookEdit): the decidable rules about where a file
goes and what it may be called.

Each check below is one rule skill's whole condition, which is why each one
denies rather than warns. Notation inside the file is a separate matter, stated
in the prose-style skill.

One exception to "whole condition": the bronze check is best-effort. It refuses
only what `check_bronze` lists.

| Check | Skill |
| --- | --- |
| kebab-case file name, with the listed exemptions | files-and-repository |
| no .jsx or .tsx anywhere | tech-layer-selection |
| no Write, Edit or NotebookEdit on a file that already exists under `bronze-source/` or the language audio from bronze in `silver-lake/languages/`, best-effort, the index `bronze-source/CLAUDE.md` excepted | medallion-layers |

A write alone does not say which command is running, so the inventory's
"this command writes only this path" rows are not decidable here and are not
checked. They stay with the model, in each command's own text.
"""

import re
import sys

from hooklib import ROOT, deny, language_audio, payload, target_paths

# files-and-repository: kebab-case, plus the closed set of exemptions that skill
# lists. Extensions and leading dots are not part of the stem being judged.
# Lowercase Latin words joined by single hyphens, with characters from a script
# that has no case and no word separator passing through unchanged. The skill
# states why: a Japanese name has no kebab form, and transliterating it would cut
# the file loose from the source material it is named after.
KEBAB = re.compile(
    r"^[a-z0-9\u3000-\u303f\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff"
    r"\uf900-\ufaff\uac00-\ud7af]+"
    r"(-[a-z0-9\u3000-\u303f\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff"
    r"\uf900-\ufaff\uac00-\ud7af]+)*$"
)
# Directories whose naming the skill exempts, each with a stated reason there.
EXEMPT_DIRS = ("silver-lake/polyglot/en/log",)
# Names that are conventions rather than content, so kebab-case does not reach
# them: they are fixed spellings other tools look for.
EXEMPT_NAMES = {
    "README", "SKILL", "CLAUDE", "AGENTS", "LICENSE", "NOTICE", "Makefile",
    "Dockerfile", "CHANGELOG", "CONTRIBUTING", "MEETING-PROTOCOL",
    # Required verbatim by a language or tool, so renaming breaks behaviour.
    "__init__", "__main__", "conftest", "py.typed",
    "settings.json", "settings.local", "km40.layout",
    "pull_request_template",
}

# Suffixes whose language makes the file name an identifier, where a hyphen is a
# syntax error rather than a style choice. The skill states this exemption too.
IDENTIFIER_SUFFIXES = {".py", ".pyi"}


def check_kebab(rel):
    """The reason the name is refused, or None when it is allowed.

    Order matters. The exempt directories and the fixed spellings are settled
    first, because a name in either class is not a casing choice at all; only then
    does the casing of an ordinary name get judged.
    """
    name = rel.name
    posix = rel.as_posix()
    if any(posix.startswith(d + "/") for d in EXEMPT_DIRS):
        return None

    stem = name
    # Strip a single trailing extension; a dotfile keeps its leading dot as-is.
    if "." in stem[1:]:
        stem = stem[: stem.rindex(".")]
    if stem.startswith("."):
        stem = stem[1:]
    if not stem or stem in EXEMPT_NAMES:
        return None

    if rel.suffix in IDENTIFIER_SUFFIXES:
        # A .py may be either casing, and which one is correct depends on how the
        # file is used: kebab-case for a script that is only executed (the hooks
        # in this directory), snake_case for a module something imports, where a
        # hyphen is a syntax error. Nothing in the path says which, so both pass
        # and only a name that is neither is refused.
        if re.match(r"^[a-z0-9]+([-_][a-z0-9]+)*$", stem):
            return None
        return (
            f"Blocked: the module name `{name}` is neither kebab-case nor "
            "snake_case. A Python file that something imports must be snake_case, "
            "because the name becomes an identifier and a hyphen is a syntax "
            "error; a script that is only executed follows the repository's "
            "kebab-case rule. Pick whichever matches how this file is used."
        )

    if KEBAB.match(stem):
        return None
    # A directory component may also break the rule, but this call only creates
    # the file, so report the name it is actually choosing.
    return (
        f"Blocked: the file name `{name}` is not kebab-case. The "
        "`files-and-repository` skill requires lowercase words joined by single "
        f"hyphens, so `{stem}` should be spelled that way. If this name is a "
        "machine-generated form that cannot be kebab-case, add its directory to "
        "the exemption table in that skill first, rather than writing the file."
    )


def check_bronze(rel):
    """Bronze is written once: a Write or Edit on an existing file under bronze-source/ or in the language audio from bronze in
    silver-lake/languages/ changes it.

    One named exception (medallion-layers, "Land in bronze"):
    `bronze-source/CLAUDE.md`, the directory index, which is not received
    data and must stay current.
    """
    if rel.parts[:1] != ("bronze-source",) and not language_audio(rel.parts):
        return None  # the language audio from bronze has no copy left in bronze, so it is guarded like bronze
    if rel.parts == ("bronze-source", "CLAUDE.md"):  # the directory index, not received data
        return None
    if not (ROOT / rel).exists():
        return None
    if rel.parts[:1] == ("silver-lake",):
        return (
            f"Blocked: `{rel.as_posix()}` already exists in the language audio from bronze under `silver-lake/languages/`. The "
            "`medallion-layers` skill keeps it as it was: it has no bronze copy, so it is "
            "never edited, overwritten, renamed, or deleted."
        )
    return (
        f"Blocked: `{rel.as_posix()}` already exists in bronze. The "
        "`medallion-layers` skill keeps every file under `bronze-source/` exactly as it was "
        "received. Land corrected or newer material as a new "
        "`bronze-source/<source>/<yyyymmddhhmmss>-<content>.<ext>` file, and do the "
        "cleaning in `silver-lake/<source>/`."
    )


def check_frontend(rel):
    if rel.suffix not in (".jsx", ".tsx"):
        return None
    return (
        f"Blocked: `{rel.as_posix()}` is a {rel.suffix} file. The "
        "`tech-layer-selection` skill rules out adding a frontend framework "
        "layer, and JSX is that layer's file form. Write the markup directly, or "
        "raise the framework question with the user before adding one."
    )


def main():
    data = payload()
    if data is None:
        return 0
    rel, _ = target_paths(data)
    if rel is None:  # outside the repository; not this repository's business
        return 0

    for check in (check_bronze, check_frontend, check_kebab):
        reason = check(rel)
        if reason:
            deny(reason)
    return 0


if __name__ == "__main__":
    sys.exit(main())
