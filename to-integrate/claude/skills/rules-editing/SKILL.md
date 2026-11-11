---
name: rules-editing
description: Editing the AI operating rule skills themselves (the files under .claude/skills/ that encode this repository's canonical AI-agent rules). Use when the user instructs a change to a rule skill's content, not when merely following the rules.
---

# Editing the Rule Skills

Edit a rule skill on an ordinary topic branch, together with everything that must change with it, so a rule and the mechanism that enforces it land in the same commit.

- Name the branch per the `rules-version-control` skill's "Branch Names", from what the change does (`update_rules`, `add_review-commit`). No branch name is reserved for rule edits, and no branch name grants or withholds the right to edit `.claude/skills/`.
- When a rule changes, change in the same commit the hooks, scripts, tests, and directory notes that enforce or describe it, and the other skills that restate it. A commit whose rule and mechanism disagree is incomplete.
- After editing a skill, run `bash .claude/skills/skill-create/scripts/test-skill.sh <name>` from the repository root and fix what it reports before committing. It checks the file-level invariants the `rules-structure` skill states (the directory and `SKILL.md` exist, the name is kebab-case, the frontmatter carries `description`, the body is not empty, no emoji); the heading invariants and the mutual exclusion of descriptions it does not check stay with the editor, read against that skill's "Heading Rules" and "Routing Exhaustiveness". The hook that ran this test on every write was retired on 2026-10-17, so nothing runs it but this step.
- The review in the `rules-version-control` skill's "Review" is what holds the first two: a pull request's review, and until that is set up the `branch-review` skill's merge gate, refuses a rule without its mechanism and a mechanism without its rule.

The justification is that review judges the change as a whole. A rule on one branch and its enforcement on another are each inconsistent on their own, so neither could pass review, and a reserved branch name would be the one privileged name in a repository that otherwise names branches by what they do.

## Skill Language

Write every skill in English by default (see the `language-selection` skill).

- Exception: when a skill's final output is in a non-English language (e.g. `write-weekly-pdca`, `meeting-memo-ocr` produce Japanese output), write only the frontmatter `description` in English; the body, output, and examples may remain in that language.

English keeps the skill index uniform and greppable, and matches the default set by `language-selection`. The exception preserves a Japanese-output skill's operative content in Japanese, because translating the output templates and examples would break their purpose; the `description` is the routing signal and stays English in all cases.
