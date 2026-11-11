---
name: review-handoff
description: Preparing a review request — the agent asking a human to review or approve its own work, or the user about to ask their own manager for a decision or approval — always leads with what changed since the last time this was reviewed, structured MECE. Use whenever work is handed off for review or approval, or when helping the user draft a message asking their manager to review or approve something.
---

# Review Handoff

Lead every review request with what changed since the last review, structured MECE per the `logical-thinking` skill, stated before any recommendation or ask for a decision. Skipping straight to the current state, or to the ask, without first stating the delta is the defect this rule forbids.

The axis is who is asking: the agent asking a human to review the agent's own work, or the user asking their own manager for a decision. Both share the same rationale — a reviewer decides fastest when handed the story of what changed instead of having to re-derive it by comparing two states themselves, and a MECE partition of that story is what keeps the reviewer from missing an item or being shown the same item twice.

## Agent Requesting Review from a Human

Before asking a human to review, approve, or sign off on work the agent produced or modified, state what changed since that human last saw it.

- Structure the changes MECE per the `logical-thinking` skill: partition by the axis a reviewer actually uses to evaluate this kind of work (e.g., by section, by concern, by file), never by chronological edit order.
- State only the delta, not the full current state — the reviewer already holds the prior state, and restating it in full spends their attention on what they already know instead of on what changed.
- When no prior review exists to diff against, say so explicitly rather than silently presenting the current state as if it were a change list.

## User Requesting Review from Their Manager

When drafting or reviewing a message the user will send their own manager to request a decision or approval, apply the same structure before it is finalized.

- Establish what the manager last saw, asking the user if it is not already known, so the change list has a baseline to diff against.
- Structure the changes MECE per the `logical-thinking` skill, using the axis the manager already applies to this kind of request where one is known, rather than inventing a new axis.

## Verification

Before the review request is sent or finalized, verify: a change-since-last-review section is present, it precedes the recommendation and the ask, and it is MECE — no changed item omitted, no item restated under two headings.
