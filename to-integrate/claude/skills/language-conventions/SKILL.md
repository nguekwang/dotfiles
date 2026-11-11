---
name: language-conventions
description: Language-specific notation conventions (character width, division marks, range notation, digits) for languages other than English, such as Japanese. Use whenever you write prose in a specific non-English language.
---

# Language-Specific Conventions

Apply the conventions of the language actually in use, on top of the general rules in the `prose-style` skill. The general rules hold regardless of language; this skill overrides only notation that is language-specific.

The axis is notation per language. Each row is a language and each column is a notation attribute, so every language is specified at the same resolution. Fill a row only when its conventions are defined; languages without defined conventions sit in the residual below.

| Language | Alphanumeric and symbol width | Intra-prose division | Range notation | Digits |
| --- | --- | --- | --- | --- |
| Japanese | Half-width | ` / ` (not `・`) | `-` (not `~`) | Half-width, grouped per three |
| English | Native | Per the `prose-style` skill | `-` | Per the `prose-style` skill |

The division column covers `・` inside a sentence. At the head of a line `・` is a different defect: Markdown renders a list only from `-`, so a line that opens with `・` stays literal text and the list is not a list. Write every list marker as `-`, in Japanese as in English.

## Undefined Languages

Korean, Chinese, Vietnamese, Burmese, and any other language absent from the table have no defined conventions yet. This is the explicit residual, not a silent gap. When you must write in one, follow the general rules and the English row as the default, and propose a new row per the `rules-feedback` skill rather than improvising a silent convention.

## Japanese Register

Japanese prose additionally carries a register, which the notation table above
does not cover.

- Write every response in 敬語 (です・ます調).
- A flat assertion is allowed; the tone stays that of a courteous technical
  document.
- 常体, an imperative tone, and colloquial phrasing are prohibited.

Register is separable from certainty: dropping politeness does not make a claim
stronger, it only narrows who will read it.
