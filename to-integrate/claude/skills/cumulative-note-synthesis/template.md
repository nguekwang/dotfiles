# template: the cumulative note skeleton

The note file the `cumulative-note-synthesis` loop writes into. Copy it, fill the
bracketed fields at setup, and let every later pass edit this one file. Section order is
fixed: the question and the schema are what each pass is judged against, the ledger and
the directives are what each pass updates, and the synthesis is written once at the end.

```markdown
# <question in a noun phrase>

## Question

<the single analytic question, one sentence>

## Schema

Axis: <the one classification axis the sections below partition>

- <section 1> — <what belongs here>
- <section 2> — <what belongs here>
- <section n> — <what belongs here>
- Other — <residual; anything the sections above do not name>

Schema changes:

| Date | Change | Reason | Sources re-read |
| --- | --- | --- | --- |

## Source ledger

| ID | Source | Status | Pass | Note |
| --- | --- | --- | --- | --- |
| S1 | <origin, date, size> | pending | - | |
| S2 | <origin, date, size> | pending | - | |

Sampling rule (when the corpus is not read exhaustively): <rule, or "none — exhaustive">

## Open directives

| ID | Directive | Defect | Raised | Rounds open | State |
| --- | --- | --- | --- | --- | --- |
| D1 | <what the next pass must look for> | absence | R1 | 1 | open |

State is one of: open, resolved (name the entry that resolved it), dead (state why this
corpus cannot answer it).

## Review log

### R1 — <date>, after S1

- Absence: <finding> -> D1
- Imprecision: <finding> -> D2
- Contradiction: <finding> -> D3
- Fragility: <finding> -> D4
- Residual: <finding, or "none">

## Evidence

### <section 1>

- <claim as stated by the source> [S1 p.3]
- <claim as stated by the source> [S2 Q4]

### <section 2>

- <claim> [S3 tbl.2]

### Other

- <claim that no section above names> [S4]

## Interpretation

<What the evidence means, rewritten freely as the corpus grows. Every statement here
points at the evidence items it rests on. Nothing here is a quotation of a source; if it
reads like one, it belongs in Evidence.>

## Known gaps

- <dead directives, unread remainder, sampling limits, dimensions the corpus is silent on>

## Synthesis

<Written last, from this note rather than from the sources, as a pyramid: the governing
conclusion first, then the support. Contradictions are reported as contradictions; known
gaps are stated, not smoothed over.>
```

## Field notes

- Source IDs (`S1`, `S2`) and review round IDs (`R1`, `R2`) are assigned once and never
  reused, so a tag written in pass 3 still resolves in pass 20.
- The ledger's `Pass` column records which pass read the source, which is what makes an
  evidence item's provenance reconstructible after a schema change.
- Keep the note in one file for as long as it stays navigable. Split only by source
  cohort (never by schema section) when it does not, since a section split across files
  hides absence — the defect the schema exists to expose.
