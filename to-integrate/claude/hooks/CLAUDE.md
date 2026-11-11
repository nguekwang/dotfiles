# Claude Code Hooks

This directory holds the deterministic guards that Claude Code runs around tool
calls. A hook enforces a repository rule mechanically, where a rule skill can
only instruct; put a rule here when compliance must not depend on the agent
reading it.

Two strengths, and the choice between them is the rule's coverage, not its
importance. `deny` is for a rule whose whole condition is mechanically decidable,
so a violation is a fact and the call stops. `warn` is for a rule where a pattern
catches the notation while the judgement it serves stays with the model: the call
proceeds and the finding is handed to the model as context. A `deny` may be
best-effort where the rule is decidable but the hook cannot see every route; the
bronze guard in `guard-write.py` is that case.

On 2026-10-17 the user reviewed every hook here and retired sixteen of them: the
per-commit review and its guards (`review-commit-msg`, `dispatch-commit-msg`,
`guard-commit.py`, `guard-main-ref`, `guard-main-push`), the context injection
(`inject-context.py`, whose facts now live in the skills and in the dotfiles
repository's `CLAUDE.md`), the notation and skill-structure linters
(`lint-notation.py`, `check-skill-structure.py`, whose rules stay in
`prose-style`, `language-conventions`, `rules-structure` and `skill-create`),
and `guard-bash.py`, `block-new-top-dir.py`, `check-dotfile-wiring.py`,
`detect-network-error.py`, `delete-merged-branch.py`, `mark-tmux-status.py` and
`grade-english.sh`. Their rules, where they survive, are statements in the skills
that the model follows; git history holds the code. On 2026-10-18 `reflect-session.py`
followed, by the user's decision (#65): every session since 2026-10-04 ran in the
cloud, where a proposal written at SessionEnd never reaches the repository, so
its prompt now runs weekly in `.github/workflows/review-sessions.yml` from
`.claude/lib/weekly-review/`, beside the grading `grade-english.sh` did.

| Hook | Event | Strength | What it checks |
| --- | --- | --- | --- |
| `hooklib.py` | n/a | n/a | Shared helpers: command detection (`is_command`), payload parsing, path resolution, the deny, warn and context protocols (every message is prefixed `[hook: <name>]`, the hook's path under this directory without its extension, so the reader sees which hook spoke), shell splitting, and the transcript-to-Markdown conversion and credential masking `export-transcript.py` uses |
| `git/install-hooks.sh` | SessionStart | acts | Installs `git/guard-pre-rebase` into this clone at every session start and removes the installed copies of the hooks retired on 2026-10-17, which a clone made before the retirement still ran (it refused this branch's first commit) |
| `list-open-issues.py` | SessionStart | context | Lists the repository's open GitHub issues (REST through `gh api`) as the resume point of the `issue-tracking` skill; silent without `gh` or on any failure |
| `guard-write.py` | PreToolUse (Write, Edit, NotebookEdit) | deny | kebab-case file names with the two exemption classes, `.jsx` and `.tsx`, Write, Edit or NotebookEdit on an existing file under `bronze-source/` or the language audio from bronze in `silver-lake/languages/`, best-effort, refusing what its `check_bronze` lists and nothing else, the index `bronze-source/CLAUDE.md` excepted |
| `guard-git.py` | PreToolUse (Bash) | rewrite, warn | A newly created branch name normalized to the permitted form (rewrite); forced worktree removal (warn) |
| `git/guard-pre-rebase` | git pre-rebase | deny (git sends nothing) | Every rebase, so the repository's history stays merge-only even for manual git commands |
| `export-transcript.py` | SessionEnd | acts | Writes the session's conversation to `.claude/sessions/` as Markdown, credentials masked |

`guard-git.py` carries the one strength the others do not: `rewrite`. Instead of
refusing a branch name that breaks the form, it derives the conforming name and
edits the command through `updatedInput`, so `git checkout -b fix-typo` runs as
`git checkout -b 2026-09-26-14-30-fix_typo`. A branch name in this repository is a
key the tooling reads rather than prose for a person, so the spelling belongs to
the machine and stopping the work over punctuation would cost more than it
protects. The rewrite fires only on creation; a command naming an existing
branch, every non-creating mode of `git branch` included, is left as typed.

Each wired hook is registered in `.claude/settings.json` under `hooks`, reads the
tool payload as JSON on stdin, and prints a decision object on stdout. A hook
stays silent when it allows a call. Every message a hook does emit, to the model
or to stderr, starts with `[hook: <name>]`, the hook's path under this directory
without its extension: `hooklib.tag()` adds it for the Python hooks' deny, warn
and context output, and a shell hook, a git hook, or a Python hook that prints
its own output writes it literally. They run from the repository root with
`.claude/hooks` on the import path, which is how each one reaches `hooklib`.

Three operational notes. A hook script is read afresh on every call, so an edit to
a script here takes effect on the next tool call. A change to the hook entries in
`.claude/settings.json` is picked up when the file changes; `/hooks` lists the
entries actually loaded, which is the check after such a change. And a rule enforced here must
also be written in the skill it comes from: the hook is the mechanism, the skill
is the statement, and a mechanism with no statement is unreviewable. Where a
hook mirrors a list from a skill, both files say so.
