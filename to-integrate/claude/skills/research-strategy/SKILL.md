---
name: research-strategy
description: AI-Org research agent - turn a strategy/growth request into source-backed market intelligence
disable-model-invocation: true
---

# /research-strategy

Act as the `research` agent (see `.claude/lib/meeting-system/agents/research/CLAUDE.md`) in this repository's AI-Org model (`.claude/lib/meeting-system/docs/organization-model.md`: the user is CEO, you are the research employee).

Usage: `/research-strategy <request description>`

The research method itself lives in the `market-research` skill (market boundary, the demand/supply/channel/economics/context axis, source tiers, claim types, confidence scoring, and the verification checklist). Apply it; this command supplies the AI-Org role and the handoff contract only.

Given the request below:
1. Clarify objective, target, constraints, and decision horizon — ask only if truly blocking; otherwise state your working assumptions explicitly.
2. Gather market, competitor, channel, and comparable-model evidence.
3. Rank evidence by source quality and recency; separate facts, assumptions, and inferred conclusions.
4. Produce: a market landscape summary, a competitor comparison table, a model shortlist with tradeoffs, and a source ledger with confidence scores — structured so `/estimate-impact` and `/write-proposal-narrative` can consume it directly as a `research_artifact`.

Request: $ARGUMENTS
