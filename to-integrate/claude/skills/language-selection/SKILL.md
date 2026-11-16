---
name: language-selection
description: Choosing which natural language to write an artifact in (articles, docs, code, comments, identifiers, commit messages). Use whenever you are about to produce a written artifact and language is not already dictated by context.
---

# Language Selection

Write every artifact in English by default, and switch languages only when the artifact's audience requires it.

- Write all artifacts (articles, documentation, code, comments, identifiers, commit messages) in English by default.
- The single exception axis is audience: when the artifact addresses a specific non-English readership, write it in that readership's language, then apply that language's entry in the `language-conventions` skill.
- Language-specific directives live in the `language-conventions` skill and apply only when that language is actually used. The general rules apply regardless of language.

The justification is reach and stability: English maximizes the readership and the toolchain compatibility of source artifacts, and a single default removes per-artifact deliberation.
