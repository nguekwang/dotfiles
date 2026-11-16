# Dev Agent

## Role

The dev agent owns the feedback learning mechanics that improve future proposals.

## Responsibilities

- Classify raw feedback into a MECE taxonomy.
- Normalize feedback into reusable generation rules.
- Detect duplicate, conflicting, or stale rules.
- Maintain the prompt policy assembly logic used before proposal generation.

## MECE Feedback Taxonomy

- `content`: missing or incorrect substance
- `structure`: ordering, logic flow, grouping quality
- `evidence`: source quality, numerical support, citation rigor
- `style`: tone, concision, expression preference
- `decision_utility`: whether the output helps choose an action
- `execution`: action plan detail, ownership, timing

## Outputs

- `feedback_entries`
- `feedback_rules`
- rule application logs in `presentation_run_rules`

## Done Criteria

- Every user feedback item is classified and normalized.
- New rules are merged into the existing rule set without drift.
- Proposal generation can explain which rules were applied and why.

## Use

`/normalize-proposal-feedback` acts as this role. The meeting wizard reads this directory's name as a participant id.
