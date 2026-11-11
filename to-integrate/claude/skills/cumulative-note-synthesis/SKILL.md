---
name: cumulative-note-synthesis
description: Synthesizing a set of source documents (survey responses, reports, competitor material, papers, interview notes, tickets) by reading them one at a time into a single cumulative note, auditing that note at fixed intervals for absence, imprecision, contradiction and fragility, and carrying the audit findings forward as explicit focus directives for the next document. Use whenever more than one source must be analyzed toward one shared question, instead of asking the model about each source in isolation.
---

# Cumulative Note Synthesis

Analyze a corpus of sources as a single accumulating note, never as a series of independent queries. One document enters per pass, its content is written into a fixed note schema, the note is periodically audited against itself, and each audit finding becomes a numbered directive that steers the next pass. The note, not the conversation, is the memory.

The axis is the loop's phase, in five ordered stages — setup, extraction, review, feedback, termination — each of which either adds to the note or constrains the next addition. The justification is retention and comparability: a model's context and a chat transcript both decay, so a durable note is the only substrate on which the twentieth document can be compared against the first, and a note that audits itself converts what the corpus is missing into an instruction rather than leaving it as a silent gap.

## Scope and Preconditions

Run this loop only when all three preconditions hold. Below them the loop costs more than it returns.

- Multiplicity: three or more sources. One or two sources are summarized directly; no note substrate is needed to compare two items.
- A shared question: every source is read toward the same analytic question. Sources that answer unrelated questions belong to separate notes, not separate sections of one note.
- Comparability as a requirement: the deliverable needs claims that hold across sources (counts, patterns, contradictions), not a per-source digest. When a per-source digest is genuinely what is wanted, produce that instead and skip the loop.

The residual case is a corpus too large to finish: when the source count exceeds what the schedule allows, fix a sampling rule before starting (most recent N, highest volume N, stratified by segment), record it in the note, and treat the unsampled remainder as an explicit known gap rather than pretending at exhaustiveness.

## Setup

Fix three things before the first document is opened. Each one is what makes a later pass comparable to an earlier one.

### The question

State the single analytic question the note must answer at the end, in one sentence. Every later decision — what to extract, what counts as a gap — is judged against it. A question that cannot be written in one sentence is two questions; split it into two notes.

### The note schema

Fix the set of sections every extraction writes into, MECE per the `logical-thinking` skill: state the classification axis, make the sections mutually exclusive and collectively exhaustive, and add an explicit residual section rather than leaving a gap. A fixed schema is what makes absence visible: an empty section is a detectable gap, whereas a free-form summary hides what was never asked.

Keep the schema stable across passes. When a pass proves the schema wrong (a real dimension has no home, or the residual section is filling up), change it deliberately as a review finding, re-read the already-processed sources against the new section, and record the schema change with its date.

### The note file and the ledger

Create one note file and, inside it, a source ledger. Place the note under `silver-lake/<domain>/`, where `<domain>` is one of the note directories of the second standing exception in `medallion-layers`, in kebab-case per the `files-and-repository` skill; write it in the language the `language-selection` skill selects for its readership. Use [template.md](template.md) as the skeleton.

The ledger carries one row per source with its identifier, its origin, its status (`pending`, `read`, `excluded`), and the pass that read it. A source that is never listed cannot be noticed as missing, so list every source up front, including those to be excluded and why.

## Extraction Pass

One document per pass. Batching several documents into one pass collapses attribution and lets the longest document dominate the summary; the per-source tag is what later makes a claim auditable.

Each pass receives exactly three inputs: the note schema, the open directives from the last review, and the one document. It produces edits to the note, not a chat answer.

- Write into the schema sections, never as an appended per-document blob. The note is organized by dimension; the source tag preserves which document each item came from.
- Tag every item with its source and location, `[S3 p.12]` or `[S7 Q4]`. An untagged item is unverifiable and, at the final write-up, unusable.
- Separate evidence from interpretation. Record what the document states in the schema sections; record what you conclude from it in an interpretation block marked as such. Evidence accumulates append-only; interpretation is rewritten freely as the corpus grows.
- Never overwrite an existing item because a new document disagrees with it. Record both with their tags and open a contradiction directive. Overwriting destroys the finding that the sources disagree — usually the most valuable one in the corpus.
- Record what the document did not contain when a schema section expected it. Silence about a dimension is evidence about the corpus.

Under Claude Code, run the extraction in a subagent when the source is long: the subagent reads the document and returns only the note edits, so the raw text never consumes the main context. The note file, not the main transcript, remains the state.

## Review Pass

At fixed intervals, audit the note against itself. Review the note alone, without the source documents in context — a reviewer holding the sources reads its own memory into the note's gaps and finds none. This is the step that distinguishes the loop from ordinary note-taking.

Cadence, by document count: after the first document, every third document thereafter, and always before the final write-up. The first review is early on purpose — it catches a broken schema while re-reading costs one document instead of twenty.

Audit against a fixed defect taxonomy. The axis is where the defect sits relative to the note's content.

| Defect | Definition | Directive it produces |
| --- | --- | --- |
| Absence | A schema section with no entries, or a dimension the question needs that the schema has no section for | Read the next sources for this dimension; or change the schema |
| Imprecision | An entry present but vague, unquantified, or not traceable to a location in its source | Re-open the named source and resolve the entry to a figure or a quotation |
| Contradiction | Two entries that cannot both be true | Determine which sources disagree and on what; report the disagreement, do not average it |
| Fragility | A claim resting on a single source, a single respondent, or one segment of the corpus | Look for corroboration or refutation in the remaining sources |
| Residual | Any defect the four above do not name | State the defect and the action explicitly |

Write the review output into the note itself, in the review log, dated and numbered — never only into the chat. A finding that lives in a chat message is lost by the next pass, which is the failure this loop exists to prevent.

The final review is asymmetric: with no pass left to steer, its findings cannot become
directives. Each one is either resolved immediately by re-opening a named source, or
recorded as a known gap in the deliverable. This asymmetry is the argument for the
interval reviews — a gap found at round two is an instruction, the same gap found at the
end is only a caveat.

## Feedback and Directive Closure

Each review finding becomes a numbered directive (`D1`, `D2`, ...) in the note's open-directives section. The next extraction pass opens with those directives stated explicitly and in full — for example, "D3: quantify the churn reasons; D5: sample sizes are missing — prioritize these while still covering the schema."

Every directive is closed explicitly, in exactly one of three states. The states are mutually exclusive and collectively exhaustive, and a directive that silently disappears is the defect this rule forbids.

- Resolved — name the note entry that resolved it and the pass that wrote it.
- Open — carried into the next pass unchanged, with its round count incremented.
- Dead — this corpus cannot answer it. State why, and the dead directive becomes a known limitation in the final deliverable rather than vanishing.

A directive open for three consecutive reviews is either dead or misstated. Decide which and record the decision; do not carry it a fourth time.

## Termination

Stop the loop when both conditions hold, and not merely when the source list runs out.

- Every ledger row is `read` or `excluded`.
- The last review produced no new absence or fragility directive, and every remaining directive is `resolved` or `dead`.

Saturation can arrive before the ledger is exhausted: when three consecutive passes add no new item to any schema section, stop reading and record the saturation point and the unread remainder in the note. Continuing past saturation buys confirmation, not information.

Write the final deliverable from the note, not from the sources — the note is by then the more complete object — and structure it as a pyramid per the `logical-thinking` skill. When the deliverable is rendered for an audience rather than kept as a working note, place it per the artifact rules of the `files-and-repository` skill.

## Verification

Before the final write-up, re-open the note and confirm each of the following. Each item corresponds to one way the loop silently degrades into unstructured note-taking.

- Every ledger row has a status, and every `excluded` row has a reason.
- Every evidence item carries a source tag with a location.
- Evidence and interpretation are separated, and no interpretation sits in an evidence section untagged.
- Every review round appears in the review log with its date and the directives it produced.
- Every directive has a closure state; none is open for more than three rounds.
- Every schema section is either non-empty or explicitly marked as having no evidence in the corpus.
- Every claim in the final deliverable traces to a tagged note entry; contradictions and dead directives are reported, not smoothed over.
