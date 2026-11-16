---
name: files-and-repository
description: Naming identifiers, files, and directories, placing new material under the existing top-level directories, and placing produced artifacts. Use whenever you name a variable/function, create a file or directory, decide where a new directory belongs, or write out a generated deliverable.
---

# Files and Repository

Name and place every identifier, file, and directory by a fixed convention, so the tree is predictable and greppable.

## Identifier Naming

Shorten identifiers as aggressively as the meaning allows. A shorter name is faster to read and type, as long as it stays unambiguous in context.

## File Naming

File names are always in kebab-case: lowercase words joined by single hyphens.
One casing across the tree removes per-file deliberation and avoids case-collision
on case-insensitive filesystems.

The rule governs the characters it can govern. A name written in a script that has
no case and no word separator, such as Japanese, carries its own characters
unchanged; what kebab-case fixes there is the separators around them, so
`CD-I46 南東部3　その魅力.mp3` becomes `cd-i46-南東部3-その魅力.mp3` rather than
being transliterated. Transliteration is rejected on purpose: it would break the
link between a file and the source material it was named after, which is the only
thing such a name is for. Latin letters are lowercased and every run of spaces,
underscores, and punctuation collapses to one hyphen, in every script.

The first exception is a machine-generated timestamp log, where the file name is a
timestamp and the separator carries meaning: `silver-lake/polyglot/en/log/` holds names of the
form `yyyy-mm-dd-HH:MM:SS.md`. The colons are the time separator, not a style
choice, and renaming them to hyphens would make the date and the time
indistinguishable. A directory claims this exception by being listed here, so the
naming check has a closed set to exempt:

| Directory | Name form | Why it is exempt |
| --- | --- | --- |
| `silver-lake/polyglot/en/log/` | `yyyy-mm-dd-HH:MM:SS.md` | The name is a timestamp; `:` separates the time fields |

A second class of exception is a language whose own identifier rules forbid the
hyphen. A Python module name is an identifier: `import http-client` is a syntax
error, so a `.py` file that anything imports must be `snake_case`. A `.py` that is
only executed, such as each hook under `.claude/hooks/`, is a script rather than a
module and stays kebab-case. Both spellings are therefore valid for `.py`, and
which one is correct follows from how the file is used, not from the path. The
same reasoning applies to any language where the file name becomes a symbol.

A third class is a name that is not a choice at all: a fixed
spelling another tool looks for. `README.md`, `SKILL.md`, `Makefile`,
`Dockerfile`, `LICENSE`, `NOTICE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `AGENTS.md`,
Python's `__init__.py`, `__main__.py`, pytest's `conftest.py`, the typing marker
`py.typed`, Claude Code's `settings.json`, `settings.local.json`, `CLAUDE.md`,
GitHub's `pull_request_template.md` and `ISSUE_TEMPLATE/`, and the meeting
system's `MEETING-PROTOCOL.md` under `.claude/lib/meeting-system/` are read by
name by something outside this repository, so spelling them in kebab-case would
break the tool rather than satisfy the rule. So is a name that pairs with another by
suffix, such as `km40.layout.json` beside `km40.json`. The test is mechanical:
the name is required verbatim by a language, a build tool, or a platform, and
renaming it changes behaviour.

A fourth class is material kept as received.
It is the user's notes that move from `notes/` into `silver-lake/`:
`anth/`, `dev/` (which took in `tech/` and `app/` on 2026-11-02), `images/`, `life/`, `math/`, `util/`
and the notes, audio and documents that come from `notes/languages/`,
and the nine loose note files at the `silver-lake/` root (`alcohol.md`, `arch.md`, `base.md`, `chemistry.md`, `claude-code.md`, `contract-creation-checklist.md`, `network.md`, `nvim.md` and `quick-note.md`).
`polyglot/` joins them from the repository root, moved on 2026-10-12 at the user's instruction.
Their directory names stay as they are, such as `c++-tutorial` or a name with `・`.
Renaming them would break the links between the notes.
The check in `.claude/hooks/guard-write.py` reads only the file name, never the
directory segments, so these directories pass without a list.
Every file name in those trees was checked and is already kebab-case, `notes/languages/` included; `silver-lake/polyglot/en/log/` is the exception, its timestamp names being allowed by the first class.
A directory added there later follows kebab-case.

Do not widen any of the four exceptions by analogy. A new generator that wants a non-kebab
name adds a row to the table above first, and a new fixed spelling belongs in the
list in this paragraph, per the `rules-feedback` skill. Both lists are mirrored in
`.claude/hooks/guard-write.py`, which enforces the rule, so a change here is
incomplete until that file matches. Directory spellings such as `ISSUE_TEMPLATE/`
are not mirrored there, because the hook judges file names only.

### Verb-Object Files

A file whose job is to perform an action — a script, a hook, a slash command —
is named `{verb}-{objective noun group}.{ext}`: the verb leads, the object it
acts on follows. A slash command's directory name `.claude/skills/<name>/` takes
the same `{verb}-{object}` form, without an extension. The `rules-structure`
skill's "Slash Commands in skills/" defines a slash command. A listing of `.claude/hooks/` or a `scripts/` directory is scanned
to answer "what does this do", and that only works when the first word is the verb.

- The verb is a plain imperative that names the action truthfully: `guard-`, `check-`,
  `detect-`, `inject-`, `lint-`, `block-`, `sync-`, `grade-`, `find-`. Prefer the verb a
  sibling file in the same directory already uses for a similar action (`guard-git.py`
  and `guard-write.py` both guard something) over inventing a near-synonym; a
  new verb should describe an action none of the existing ones cover, not restate one
  that already has a name. Take the verb from what the file actually does, documented
  in its own header comment, rather than from its working title: `english-judge.sh`
  became `grade-english.sh`, not `judge-english.sh`, because its own comments call the
  action "grading", not "judging".
- Object-first order (`english-judge.sh`, `vc-guard.py`, `vc-sync.sh`) hides the action
  behind the domain word and reads as a label rather than an instruction; a file already
  in the tree spelled this way is a violation to fix, not a precedent to match.
- The rule reaches a file only when its whole name is one action. It does not reach a
  fixed spelling (`__init__.py`, `CLAUDE.md`), a role or domain label that names a thing
  rather than an act (a role directory name such as `reviewer/` under an agent-roles directory). A
  namespace prefix is not an exemption: a slash command is an action file, so
  `org-research` was renamed to lead with its verb (`/research-strategy`). Nor does it reach `test/<area>-test.sh`: the
  suffix is required verbatim by `test/all`'s glob and documented in `test/CLAUDE.md`, so
  it is a fifth naming exception beside the four in "File Naming" above,
  not a case of this rule.

Verification before naming or renaming an action file: state the verb and the object
separately, confirm the verb comes first, and check the directory for a sibling that
already uses a different verb for the same object before picking a new one.

## Directory Structure

- Every directory must contain a `CLAUDE.md`. It holds the system prompt written for AI agents, the directory-specific complement to the rule skills. Claude Code loads it by that name as context for work in that directory. There are three exceptions. The first is a bronze source directory under `bronze-source/` and everything below it: its note is `main.md` per the `medallion-layers` skill, and a subdirectory inside the source carries whatever the source came with, because all of it is bronze data and is never renamed or added to. `bronze-source/` itself, being no source, carries a `CLAUDE.md`. `silver-lake/languages/` carries a `CLAUDE.md`. The language audio from bronze under it (`french-verb/`, `french-vocabulary/`, `portuguese/`, `phonetics/` and `main.md`) is the same kind of material, kept as it was received, so it carries no `CLAUDE.md` either; its note is `main.md`. The second is the user's moved notes, audio and documents named in the fourth class of "File Naming" (the loose root note files have no directory to carry one). They carry no per-directory `CLAUDE.md` unless they already had one. A directory added there later carries one. The third is `.claude/skills/` and everything below it, and none of them carries a `CLAUDE.md`. A skill's `SKILL.md` is its directory's prompt, per the official `.claude` layout, and the `scripts/` and `references/` inside a skill are that skill's own material.
- For a Markdown table separator inside any file, use exactly three hyphens; the form rule lives in the `figure-rendering` skill.

### Top-Level Directories

The set of directories directly under the repository root is fixed. Creating a new one is prohibited unless the user explicitly instructs it in the current task.

- Place every new file and every new directory inside an existing top-level directory. Choose the one whose subject already covers the material, and nest as deep as the subject requires.
- Never add a top-level directory on your own judgement, and never add one as a side effect of another task. When no existing top-level directory fits, say so and ask; do not create a root entry and report it afterwards.
- A user instruction to create a top-level directory authorizes exactly that one directory, in that one task. It does not carry over to a later task.
- The root `.gitignore` declares the top-level directories added after the import, and a top-level directory is allowed when it already exists on disk or is declared there. One added after the import is declared by a `!/<name>/` line: `silver-lake/` (silver refined data) and `golden-mart/` (gold deliverables), both per the `medallion-layers` skill, and `.github/` (GitHub's issue and PR templates and workflows). The line does not change what git tracks; it is the declaration the agent reads, so adding a top-level directory means the user instructs a new `!/<name>/` line. The directories that existed at the import, `.claude/` and `bronze-source/` among them, are not on the list and stay allowed because they exist.
- Residual: material that fits no existing top-level directory and whose placement the user has not yet decided stays out of the tree — keep it in the scratch location of the current session until the user rules on it.

The root is the repository's index: a reader scans it once to learn what the repository holds, so a stable root keeps that index readable and keeps every path predictable from its first segment. Each new root entry, by contrast, widens the classification axis at the top level and costs every future reader a re-scan, which is a decision the user owns rather than the agent.

Verification before creating any directory: resolve its path's first segment, and confirm that directory already exists on disk or `.gitignore` declares it with `!/<name>/`. If neither holds, the creation needs the user's explicit instruction and a new `!/<name>/` line.

This imported repository's root `.gitignore` only ignores Python bytecode (`__pycache__/`, `*.pyc`) and has no ignore-all line; its `!/<name>/` lines (`!/silver-lake/`, `!/golden-mart/`, `!/.github/`) only declare top-level directories added later. Do not invent a root ignore-all policy.

### Inside `.claude/`

Existing Claude-specific configuration, runtime support, and records remain under `.claude/`. Directories within `.claude/` are cut MECE: each child of `.claude/` answers one question on one axis, no two children overlap, and together they leave nothing without a home. The axis is what the material is, read by who produces it and who consumes it:

| Group | Children | What belongs there |
| --- | --- | --- |
| Configuration Claude Code reads | `settings.json`, `settings.local.json`, `keybindings.json`, `skills/`, `agents/`, `hooks/`, `plugins/` | Files whose names and places Claude Code itself fixes |
| Code and documents that are run or read, not loaded | `lib/` | Scripts, servers and documents that a skill, command or hook runs or cites, or that the user runs directly (`lib/tools/`), but that Claude Code does not load by itself |
| Records the work produces | `log/`, `reviews/`, `sessions/`, `rule-proposals/` | Durable history: a branch's running record, its review rounds, each session's conversation, and proposed rule changes |

- Before creating a directory under `.claude/`, name the group it falls in and check its siblings: when an existing child already covers the material, nest inside it instead of adding a sibling.
- A new child of `.claude/` is added only when no existing child covers the material, and it joins exactly one group in the table above. Add its row entry here in the same change, so the table stays the complete list.
- Never add a child whose name Claude Code reserves for another purpose (for example `rules/`, `agents/`, `output-styles/`), unless the material is exactly what Claude Code loads from it.
- Every new directory carries a `CLAUDE.md`, per "Directory Structure" above.

Verification before creating a directory under `.claude/`: state the group, confirm no sibling already covers the material, and confirm the table lists the new child after the change.

## Artifact Output

Write every produced artifact into one fixed directory under a timestamped name, so generated material stays out of the source tree and remains greppable in one place. An artifact is any material produced as a deliverable, distinct from the repository's own source files. Artifacts are the gold layer of the `medallion-layers` skill: one built from outside data reads from silver only and names the silver files it used.

- Place every artifact in `golden-mart/`, the gold top-level directory. Never scatter produced material across the source tree.
- Name each artifact `yyyymmddhhmmss-<content>.html`, where `yyyymmddhhmmss` is the creation timestamp and `<content>` is a nominal group describing the artifact in kebab-case per "File Naming" above.
- The timestamp prefix orders artifacts chronologically and removes name collision; the nominal group states the subject. The rationale mirrors the `yyyy-mm-dd-hh-mm-` branch form in the `rules-version-control` skill's "Branch Names": a creation-time prefix is a stable, sortable key.
