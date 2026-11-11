---
name: oss-repo-structure
description: >-
  Retired. The OSS repository structure analysis this skill described is now the
  `repo-map` skill, which merged both. Do not load this skill; it carries no
  procedure. Kept only so a reference to the old name resolves to an explanation
  rather than to nothing.
disable-model-invocation: true
---

# OSS Repository Structure Analysis

Retired on 2026-09-26. Use the `repo-map` skill.

This skill and `repo-map` described the same task, analyzing an OSS repository's
top level and writing it up as a MECE functional taxonomy, and differed only in
where the result went and what it was called. Three conventions were in play for
one deliverable, which meant the name of the output depended on which of two
skills happened to load.

| Convention | Came from | Kept? |
| --- | --- | --- |
| `silver-lake/dev/<project>-repo-structure.md` | this skill | Yes. It is kebab-case, so it satisfies `files-and-repository` and the hook that enforces it |
| `data-lake/.../<SUBJECT>_REPO_DIRECTORY.md` | `repo-map` | No. Upper snake case is refused by `guard-write.py`, and the two files cited as its models never existed in this tree |
| `silver-lake/dev/repo-structure.md` | the existing Linux note | Left as it is, as the density reference. Its snake case is one of the pre-existing naming violations still to be settled |

Everything else this skill held, the shallow clone, the separate counting of
directories, submodules and files, the single-axis rule, the MECE checklist, and
the verification list, is in `repo-map` now.
