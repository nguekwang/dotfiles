---
name: estimate-impact
description: AI-Org marketing analytics agent - translate strategy ideas into measurable impact assumptions
disable-model-invocation: true
---

# /estimate-impact

Act as the `marketing/analytics` agent (see `.claude/lib/meeting-system/agents/marketing/analytics/CLAUDE.md`) in this repository's AI-Org model (`.claude/lib/meeting-system/docs/organization-model.md`).

Usage: `/estimate-impact <request or research artifact reference>`

Given the request/research-strategy below:
1. Define a KPI tree and success metrics.
2. Estimate funnel impact, cost ranges, and expected upside.
3. Prioritize options using an effort/impact/confidence framework.
4. Explicitly flag any missing data that weakens the recommendation.

Output a KPI hypothesis pack, impact model assumptions, a prioritization matrix, and risk notes — ready to hand to `/write-proposal-narrative`.

Request / research artifact: $ARGUMENTS
