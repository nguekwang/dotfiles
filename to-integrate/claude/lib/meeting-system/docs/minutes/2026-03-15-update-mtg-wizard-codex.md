---
title: update-mtg-wizard
meeting_name: update-mtg-wizard
topic: update-mtg-wizard
date: 2026-03-15
timestamp: 2026-03-15T18:22:11+09:00
tool: Codex
meeting_type: general
participants: all
objective: Switch question items depending on mtg type
constraints: None
started_from_branch: mtg/2026-03-15-separate-shell-scripts
branch: mtg/2026-03-15-update-mtg-wizard
status: final
---

# Meeting: update-mtg-wizard

## Agenda

- Update the meeting setup wizard so its interactive questions change by `meeting_type`
- Keep the generated meeting metadata stable so downstream scripts do not need to change
- Document the new wizard behavior

## Current Focus

- Wire type-specific prompt labels and defaults into the interactive meeting wizard

## Summary

This meeting updates the meeting setup wizard so the interactive questions shown after `meeting_type` selection depend on the chosen meeting type. The implementation keeps the existing generated metadata shape intact by varying prompt labels and defaults rather than changing the stored fields or command-line contract.

## Context

The repository already supports multiple meeting types, but the wizard always asked the same generic questions for all of them. The requested change is to make the interactive question items match the semantics of `general`, `issue-triage`, and `report-qa` meetings without breaking minutes generation or downstream automation.

## Discussion

### User

- Requested that the wizard switch its question items depending on meeting type.

### PM

- The meeting start flow should feel aligned with the selected meeting mode so the operator is not translating generic prompts mentally.
- The change should stay narrow and avoid forcing changes into minutes storage or close-out automation.

### Dev

- Added type-specific prompt label and default helpers in [scripts/utils/start-meeting.sh](../../scripts/utils/start-meeting.sh).
- Kept the underlying stored values as `meeting_name`, `purpose`, and `constraints` so `create-minutes.sh` and finalize flows remain compatible.
- Updated [docs/minutes/README.md](README.md) to describe the new wizard behavior.

### Ops

- Preserving the existing metadata contract avoids regressions in branch creation, minutes generation, and end-of-meeting automation.
- The wizard still works non-interactively because only interactive labels and defaults were changed.

## Review

- CEO perspective:
- The requested UX change is implemented without broad workflow churn.
- World-class engineering perspective:
- The change isolates meeting-type behavior in explicit helper functions instead of scattering conditionals across the wizard.
- Elite strategy consulting perspective:
- This is a small but useful workflow refinement because the meeting entry path now better matches operator intent.
- Verdict: approved

## Decisions

- The meeting setup wizard should vary its interactive prompt labels and defaults by `meeting_type`.
- The stored metadata fields remain unchanged as `meeting_name`, `purpose`, `constraints`, and `participants`.
- Documentation should describe the type-specific wizard prompts so the behavior is discoverable.

## Open Questions

- Whether a future change should also vary the minutes template sections by `meeting_type`, not just the setup prompts

## Parking Lot

- Whether the minutes template itself should become type-aware in a later meeting

## Action Items

- Owner: User
- Task: Decide whether to prioritize a follow-up change that makes the minutes template vary by `meeting_type`.
- Due: TBD

## References

- [scripts/utils/start-meeting.sh](../../scripts/utils/start-meeting.sh)
- [docs/minutes/README.md](README.md)
- [docs/minutes/MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
