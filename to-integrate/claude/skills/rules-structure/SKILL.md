---
name: rules-structure
description: Maintaining the structure of the AI operating rule skills under .claude/skills/ (this repository's canonical AI-agent rules). Use when adding, renaming, removing, or reorganizing a rule skill, or judging whether a rule belongs in an existing skill or needs a new one.
---

# Rule-Skill Structure

The AI operating rules for this repository live as a set of individually-triggered Claude skills instead of one monolithic file. Preserve the following invariants whenever the rule set itself changes.

## Slash Commands in skills/

A skill whose frontmatter sets `disable-model-invocation: true` is a slash command, not a rule skill.
One exception is a retired pointer: a skill whose `description` starts with "Retired." keeps the flag only so it never routes.
It is not a command, and `hooklib.is_command` applies the same test. It lives in `skills/` because the official `.claude` layout makes `skills/<name>/SKILL.md` the form of a command, and it is invoked only by `/<name>`. The rest of this skill governs the routed rule set; a slash command is exempt from these invariants:

- Clean Architecture Layering: it joins no layer.
- Uniform Resolution: it need not match the density of the rule skills.
- Routing Exhaustiveness: its `description` is not on the routing surface.
- Heading Rules, the descriptive-title clause only: its heading 1 may be the invocation string (`# /<name>`), because the command was a bare prompt file before the move and the string is how the user finds it.

It keeps the file-level invariants of every skill: frontmatter with `name` equal to the directory and a `description`, exactly one heading 1, no heading 4 or deeper.

## Skill Boundaries

Each rule skill owns exactly one classification axis. Where two skills touch, the owner states the rule and the other references it by name (`see the <skill-name> skill`), never restates it.

- One skill, one axis. Mixing axes in a single skill is a defect; split it.
- A primitive presentation form (prose, speech, a figure, a code snippet, a file name) is owned by its form skill. A composite task (transcription, installation steps, configuration edits) references those forms rather than copying their rules.

## Clean Architecture Layering

Group and name skills inner to outer, so the stable core sits conceptually first and the volatile environment sits last. Dependencies point inward: an inner-layer skill never depends on an outer-layer one.

- Governance — rules for operating this rule set itself (`rules-structure`, `rules-feedback`, `rules-editing`, `rules-version-control`).
- Core Identity (Entities) — who the agent is. The most stable layer (`persona`, `comprehension-first`, `logical-thinking`, `conversation-management`, `review-handoff`).
- Reasoning and Selection Policy (Use Cases) — how the agent reasons and chooses (`language-selection`, `tech-layer-selection`, `tool-evaluation-installation`).
- Expression and Presentation (Interface Adapters) — how the agent renders output (`prose-style`, `language-conventions`, `speaking-rules`, `figure-rendering`, `technical-rendering`, `files-and-repository`, `image-pdf-transcription`, `installation-steps`, `config-file-editing`, `cli-command-template`).
- Environment (Frameworks and Drivers) — concrete external assumptions. The most volatile layer (`environment-assumptions`, `dotfile-deployment`, `issue-tracking`).

## Uniform Resolution

Hold every skill at the same construction and density. Match each skill to the most detailed existing one, so no skill reads thinner than another.

- Construct every skill from the same elements: a governing conclusion first, an explicit classification axis before any list, a rationale stated as a capability or stability argument, subsections when the content has parts, and a verification step or an explicit residual.
- When a set cannot be fully covered, add an explicit residual category rather than leaving a thin or empty skill.
- A skill that states a rule without its rationale is under-resolved. Raise it to the benchmark; do not pad the others down to meet it.

## Heading Rules

Every `SKILL.md` follows the same heading invariants so the skill set reads as one structure.

- Heading 1 is the title only. It is the descriptive title on line 1 of the file. Do not add, edit, or delete it, and never introduce a second heading 1.
- Heading 2 is the unit of navigation. Each heading 2 holds one subsection of the skill (a classification axis or a discrete rule block); the reader reaches sections by heading 2, never a deeper level, and navigation or documentation outside the file references heading 2 (or the skill itself), never heading 3.
- Heading 3 is local to its parent heading 2. Reference a heading 3 only from within the same heading 2. A heading 3 must never be the target of a reference from another heading 2, from another skill, or from the routing surface (description or entry pointer).

## Routing Exhaustiveness

Each skill's frontmatter `description` is its routing signal — the trigger condition Claude uses to load it. Keep the set of descriptions exhaustive and mutually exclusive:

- Every rule topic in this repository must be reachable from exactly one skill's description.
- When you add, rename, or remove a skill, update its `description` and check that no other skill's description now overlaps or leaves a gap.
- Keep the routing surface exhaustive: every skill is reachable from exactly one routing row (`description` or an entry pointer), and every routing row points to an existing skill. When you add, rename, or remove a skill, update its routing row in the same edit.
