---
name: image-pdf-transcription
description: Transcribing a screenshot, image, or PDF page into normalized Markdown. Use whenever the user asks to transcribe, OCR, or convert a rendered page (a book screenshot, a PNG, a JPEG, or a PDF page) into Markdown.
---

# Image and PDF Transcription Rules

Transcribe a source page into Markdown that is faithful in content and normalized in notation. Faithfulness governs what the text says; this skill governs how it is written. The two never collide: copy every word, and rewrite every notation to the canonical form below.

The source is any rendered text page, not only a Kindle screenshot. A PNG, a JPEG, and a PDF page are all in scope, and every rule below applies to each identically.

## Content Fidelity

- Transcribe the whole source. Never summarize, abridge, or drop a passage.
- Exclude reader chrome that is not part of the text, such as a `Page 256 of 689` locator or a `37%` progress indicator.
- Treat the body as continuous even when page numbers skip. A reader renumbers pages, so a gap in the numbering is not a gap in the text. Do not report a missing page from a number gap alone.
- Ignore a re-uploaded duplicate page. Reflect its body once.
- When characters are illegible, reconstruct the natural reading from context. Note the reconstruction only when the inference is large, and collect such spots in the report.

## Notation Normalization

Apply every rule in the `prose-style` and `language-conventions` skills to the transcription, overriding the source wherever the source diverges. Fidelity is owed to the words, not to their typography.

- Follow the `prose-style` skill's "Symbols and Numbers": group digits, insert no thematic break, add no decorative character.
- Follow the `language-conventions` skill for the language of the transcription. For Japanese, apply the Japanese row: half-width symbols and alphanumerics, ` / ` for division, `-` for a range.
- This normalization is exhaustive. Every rule in those skills applies, not only the ones named here.

## Structure

- Map the source hierarchy to heading levels: chapter to `#`, section to `#` or `##`, sub-section to `##`, inline sub-heading to `###`.
- Render a footnote as a `>` quote block to separate it from the body.
- Render binary, decimal, an address, and a bit string in a fenced code block.

## Figures

Follow the `figure-rendering` skill first: tabular content is a Markdown table, every other figure is Mermaid, and a bit-aligned figure is an aligned text diagram per the `technical-rendering` skill.

- Reproduce a concept, network, flow, or sequence figure in Mermaid, choosing the diagram type by the `figure-rendering` skill.
- Title each figure `**図 X.Y タイトル**`, and attach the original caption and notes as a `>` quote.
- Render a bit-field structure diagram, such as an address format, by the `technical-rendering` skill: an aligned text diagram in a code block, or a table. Mermaid cannot hold per-bit alignment.
- When a detail is unreadable, such as a complex topology or an in-cell number, reconstruct the figure as a concept diagram and note the reconstruction below it.

## Output and Continuation

- Collect one book, or one chapter, into a single `.md` file.
- Append a continuation page to the same file. Before appending, read the end of the last page so the body joins without a break.
- On repository work, commit and push per the `rules-version-control` skill.

## Report Format

After each batch, report:

- the page range taken in,
- the duplicates detected and ignored,
- the spots reconstructed from illegible text, if any,
- the start page to send next.
