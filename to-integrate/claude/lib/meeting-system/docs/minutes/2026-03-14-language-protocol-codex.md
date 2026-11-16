# Meeting: language-protocol

- Date: 2026-03-14
- Tools: Codex
- Meeting Type: general
- Participants: User, dev agent, research agent, reporting agent
- Topic: language-protocol
- Objective: Determine the language policy

## Agenda

- Clarify the scope of the language policy
- Evaluate language choices by role and artifact
- Converge on an initial policy and follow-up work

## Current Focus

- Define an equal-status multilingual policy without first-class language tiers

## Summary

This meeting defined a mixed-audience language policy for internal and external artifacts. Codex discussion may remain in Japanese, while all durable internal artifacts, including issues, PRs, and meeting minutes, are standardized in English. External documentation is authored in English as the canonical source and then translated into other languages under an explicit, strict, and language-specific governance model.

## Context

The user requested a meeting-mode discussion with role-based statements, running memo diffs, Parking Lot handling, and a final Markdown-ready output. The repository already defines a meeting protocol under `docs/minutes/`, and this session follows that format on an `mtg` branch.

## Discussion

### User

- The meeting name is `language-protocol`.
- The meeting type is `general`.
- The purpose is to determine the language policy.
- Constraints are currently `None`.
- Participants are `all`.
- The policy should cover both internal and external use.
- Codex discussion may be in Japanese.
- Internal-facing documentation should be unified in English.
- External-facing documentation should be created in English first, then translated into multiple languages.
- Translation rules should be strict, including handling of loanwords and constraints on language-specific grammatical features.
- Internal issues, PRs, and meeting minutes should also be unified in English.
- When natural in the target language, native equivalents should be preferred over retaining English loanwords.
- The translation policy should be precise per language.
- Political and social sensitivity in wording should be handled carefully.

### Dev

- The policy should be defined per artifact rather than as one blanket rule.
- Durable artifacts should use English to preserve searchability, reviewability, and long-term consistency.
- English should be the explicit source-of-truth language for durable documents, and translations should be derivative artifacts linked to a source version.
- Translation governance should be represented as enforceable rule classes such as glossary, no-translate list, transliteration rules, punctuation rules, and sentence-structure constraints.
- The policy should use a two-layer model: a global translation constitution plus equal-status per-language profiles.
- Per-language profiles should define morphology, syntax, register, orthography, punctuation, compounding, loanword adaptation, and inclusive-language constraints.

### Research

- Mixed-audience repositories benefit from one canonical written language for durable records.
- Translation quality is stabilized by central terminology management: glossary, no-translate list, approved abbreviations, and per-language style restrictions.
- Loanword handling should be split into explicit categories: keep in English, transliterate, or replace with an established native equivalent.
- The preferred default is `native equivalent > established loanword > English retention`.
- A linguistically rigorous policy should specify decision criteria such as semantic precision, term entrenchment, audience familiarity, and conflict with protected or exclusionary language.
- Inclusive-language rules should be defined per language, because politeness, gender marking, and person-reference systems differ structurally across languages.
- Fairness across languages should be achieved by a uniform policy schema, uniform metadata, and uniform review expectations, without normative ranking among languages.

### Reporting

- The policy should remain simple at the top level: English for durable artifacts, Japanese allowed for Codex discussion, English-first for external source documents.
- For external publishing, the policy should state that English is the original version and translations are localized derivatives.
- The policy should require translation metadata such as source version, translation status, and reviewer ownership.
- The final policy should be publishable as one core policy document plus one equal-status profile per language.

## Decisions

- Codex discussion may be conducted in Japanese.
- Internal-facing documentation is standardized in English.
- External-facing documentation is authored in English as the original source and then translated into other languages.
- English is the canonical source language for durable documentation, and translations are derivative artifacts tied to the English original.
- Translation governance will be defined explicitly rather than handled ad hoc.
- Internal issues, PRs, and meeting minutes are included in the English-only rule for durable artifacts.
- Translation policy follows a naturalization-first principle: when a target language has a natural and established native equivalent, it should be preferred over retaining English.
- Translation policy will be defined per language, not only as one universal rule set.
- Socially sensitive and potentially exclusionary wording must be explicitly considered in translation policy.
- Supported languages are treated as equal in normative status; the policy must not define privileged translation languages such as `first-class` versus `secondary`.

## Open Questions

- Which terms are always kept in English, which are transliterated, and which must use established native equivalents?
- Which language-specific grammatical features should be constrained for each target language?
- How should source-version tracking and translation freshness be managed?
- How should inclusive-language constraints be defined for languages with grammatical gender, honorific systems, or obligatory person marking?
- How should governance handle the practical case where some language profiles are more fully specified than others at a given point in time, without creating normative hierarchy?

## Parking Lot

- Tooling support for automatic translation or linting, if needed later.
- Whether translation production is machine-assisted, human-only, or hybrid.

## Action Items

- Owner: Dev
- Task: Draft the artifact taxonomy separating live discussion, internal durable docs, external source docs, and translated derivatives.
- Deliverable: A policy section or appendix defining artifact classes and language requirements.
- Due: TBD

- Owner: Research
- Task: Draft translation rule categories covering glossary, no-translate list, loanword policy, and per-language grammar constraints.
- Deliverable: A translation-governance outline with rule classes and decision criteria.
- Due: TBD

- Owner: Reporting
- Task: Draft publication metadata rules for source version, translation status, and reviewer ownership.
- Deliverable: A metadata specification for source linkage, freshness, and review responsibility.
- Due: TBD

- Owner: Research
- Task: Draft a language-profile template covering register, orthography, morphology, syntax, punctuation, terminology, and inclusive-language constraints.
- Deliverable: A reusable language-profile template with equal-status governance fields.
- Due: TBD

## References

- [MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [template.md](template.md)
