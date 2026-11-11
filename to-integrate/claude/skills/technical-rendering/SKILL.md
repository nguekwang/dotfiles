---
name: technical-rendering
description: Rendering technical content in monospace output — aligned text diagrams (such as RFC packet diagrams) and formatted code snippets. Use whenever you produce a bit/column-aligned diagram or a fenced code block.
---

# Technical Rendering Rules

Rules for rendering technical content in monospace output: text diagrams and code snippets. Both assume a monospace context, where one character is one column. Alignment is correctness, not decoration.

## Text-Based Diagrams

Keep every column aligned across every row. A diagram whose separators drift between rows is a defect, not a style choice.

- Fix one unit per character column, and hold that unit constant across all rows. In an RFC packet diagram one cell is one bit; the top ruler numbers the bits and `+-+-+` is the per-bit ruler.
- Vertical separators (`|`), tick and corner marks (`+`), and cell borders (`-`) must occupy the same column in the rows above and below. A `|` that does not line up with the `+` above and below it is the defect to fix.
- Before presenting a diagram, verify alignment column by column. Confirm each `|` and each `+` shares a column with the marks in the adjacent rows.
- Render and check in a monospace font. A diagram that aligns only in a proportional font is defective.

## Code Snippets

Write every snippet in the target's real syntax and format it deliberately, then verify both before sending. Treat syntax and formatting as part of the deliverable, not an afterthought.

- Write snippets in the actual syntax of the language, tool, or configuration format being shown, valid as typed. Pseudocode, an invented flag, or a placeholder API is a defect: the reader's first action is to run the snippet, so a snippet that does not survive that is worse than none.
- Enclose every snippet in a fenced code block tagged with its language.
- Apply the language's standard formatter conventions: fixed indentation width, one indentation style (spaces or tabs, never mixed), and consistent alignment.
- Remove trailing whitespace and avoid stray blank lines.
- Align related elements that read in columns: aligned inline comments, aligned continuation markers, aligned table-like literals.
- Comment in concise English (see the `language-selection` skill): one clause per comment, stating what the line is for rather than restating what it does. A comment that repeats the code adds width without adding information.
- Before sending, re-read the snippet and confirm the syntax is valid as typed and the indentation and alignment are consistent throughout.
