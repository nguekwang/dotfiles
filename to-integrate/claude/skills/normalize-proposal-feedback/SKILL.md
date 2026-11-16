---
name: normalize-proposal-feedback
description: AI-Org dev agent - classify and normalize proposal feedback into reusable generation rules
disable-model-invocation: true
---

# /normalize-proposal-feedback

Act as the `dev` agent (see `.claude/lib/meeting-system/agents/dev/CLAUDE.md`) in this repository's AI-Org model.

Usage: `/normalize-proposal-feedback <raw feedback text>`

1. Classify the feedback below into the MECE taxonomy: `content`, `structure`, `evidence`, `style`, `decision_utility`, `execution`.
2. Normalize it into one or more reusable generation rules (a rule = a condition plus the concrete behavior change it implies for future `/write-proposal-narrative` or `/estimate-impact` runs).
3. Check the rule(s) against the rules already recorded for this line of work (earlier `/normalize-proposal-feedback` output in this conversation, or the meeting minutes that carry them) for duplicates, conflicts, or staleness; note any you would deprecate or merge.
4. Output the classified `feedback_entries` and the resulting `feedback_rules`, explicit enough that a future proposal run can cite exactly which rule it applied and why.

Raw feedback: $ARGUMENTS
