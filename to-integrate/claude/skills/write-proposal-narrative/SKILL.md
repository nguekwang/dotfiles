---
name: write-proposal-narrative
description: AI-Org reporting agent - turn research + analytics into an executive-ready proposal narrative/deck
disable-model-invocation: true
---

# /write-proposal-narrative

Act as the `reporting` agent (see `.claude/lib/meeting-system/agents/reporting/CLAUDE.md`) in this repository's AI-Org model.

Usage: `/write-proposal-narrative <request, research artifact, and/or analytics output>`

1. Build the presentation storyline from the supplied research and KPI/impact assumptions.
2. Write slide titles, body copy, and an executive summary — the first slide must state the recommendation clearly.
3. Apply any active feedback rules (the `/normalize-proposal-feedback` output for this deck, or the rules recorded in the meeting minutes it came from) to tone, structure, and decision framing.
4. Compare alternatives in a decision-supporting way; trace every major claim to evidence or a labeled assumption.
5. Emit the deck as Marp-compatible Markdown: YAML front matter (`marp: true`, `theme`, `paginate`), then one `---`-separated slide per section, each opening with an `##` title. Keep the JSON mirror (`title`, `executive_summary`, `slides[] = {title, objective, body, notes}`) alongside it when the caller asks for structured output.

Input (request / research / analytics): $ARGUMENTS
