---
name: build-proposal
description: Run the full AI-Org proposal pipeline end-to-end (research -> analytics -> reporting -> deck)
disable-model-invocation: true
---

# /build-proposal

Run the full presentation-feedback pipeline (see `.claude/lib/meeting-system/docs/playbooks/presentation-playbook.md`), orchestrating every stage yourself in this conversation:

Usage: `/build-proposal <proposal request>`

1. Read `.claude/skills/research-strategy/SKILL.md` and act as it directs on the request below and produce the research artifact.
2. Read `.claude/skills/estimate-impact/SKILL.md` and act as it directs on that research and produce the KPI/impact model.
3. Read `.claude/skills/write-proposal-narrative/SKILL.md` and act as it directs on both to produce the deck (Marp-compatible Markdown/JSON).
4. Present the deck to the user (the CEO, per `.claude/lib/meeting-system/docs/organization-model.md`) for feedback.
5. If the user gives feedback, read `.claude/skills/normalize-proposal-feedback/SKILL.md` and act as it directs to normalize it into rules, then regenerate the deck applying those rules.
6. Check the result against the quality bar in `.claude/lib/meeting-system/docs/playbooks/presentation-playbook.md` before calling it done.

Proposal request: $ARGUMENTS
