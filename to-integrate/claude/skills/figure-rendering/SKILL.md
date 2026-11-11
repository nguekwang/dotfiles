---
name: figure-rendering
description: Rendering a table or any figure (Mermaid diagrams, visual style). Use whenever you present tabular content or any non-text figure.
---

# Figure Rendering

Render every figure in the one form its content dictates, then style it uniformly. Form selection comes first; visual style applies to whichever form results.

## Form Selection

Select the rendering form from the shape of the content. The three cases are mutually exclusive.

- Tabular content is a Markdown table; see "Tables" below.
- A figure that requires exact per-column or per-bit alignment, such as an RFC packet diagram, is an aligned text diagram; see the `technical-rendering` skill.
- Every other figure is Mermaid; see "Diagrams" below.

## Tables

Render all tabular content as a Markdown table. Drawing a table with ASCII separators or whitespace alignment is prohibited.

The delimiter row uses exactly three hyphens (`---`) per column. This is the single exception to the thematic-break prohibition in the `prose-style` skill.

Decide the header row strictly from what the table represents. The two cases are mutually exclusive.

- A relation has a header. When each column is a meta attribute and each row is a record, in the manner of a relational-database schema, the first row names those attributes and is the header.
- A grid has no header. When the content is a plain two-dimensional array of values, with no row that names attributes, there is no header row. Leave the Markdown header cells empty so the first data row is not read as a header.

## Diagrams

Render every non-tabular, non-bit-aligned figure in Mermaid, enclosed in a fenced code block tagged `mermaid`. Choose the diagram type that matches the content: `flowchart` for control or data flow, `sequenceDiagram` for interactions over time, `erDiagram` for entity relationships, `classDiagram` for type structure, and `stateDiagram` for state transitions.

A figure that requires exact per-column or per-bit alignment cannot be expressed in Mermaid and follows the `technical-rendering` skill instead.

## Visual Style

These styling rules apply to every rendered figure, whether a generated image or a Mermaid diagram. The axis is appearance, held constant so figures read as one set.

- Japanese font-family is Meirio.
- font-weight is bold.
- font-color is dark-gray.
- Use alignment for left / center / right. Never align with whitespace.
- Emphasis color coding
  - Positive content is "blue"
  - Negative content is "red"
- Keep text on the same layer at a uniform font size.
