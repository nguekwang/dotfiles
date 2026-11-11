---
title: meeting-ops
meeting_name: meeting-ops
topic: meeting-ops
date: 2026-03-14
timestamp: 2026-03-14T19:08:19+09:00
tool: Codex
meeting_type: general
participants: User, dev agent, research agent, reporting agent
objective: Define the standard meeting workflow, review model, and organization interpretation
constraints: Durable artifacts should be in English; finalize the meeting workflow and minutes governance
started_from_branch: main
branch: mtg/2026-03-14-meeting-ops
status: final
---

# Meeting: meeting-ops

## Agenda

- Redefine `report-qa` meetings so the user asks questions and AI agents answer
- Allow multiple agendas within one meeting while keeping a single current focus
- Implement the currently spec-only AI agents and a local workflow harness
- Add AI review lenses and clarify the organization metaphor
- Require rich YAML front matter in minutes
- Automate meeting start and finish workflow
- Standardize the meeting workflow and prompts in English

## Current Focus

- Finalize the durable meeting workflow and save this session as reusable organizational policy

## Summary

This meeting formalized how meetings should run in this repository and how those meetings map to the anthropomorphized AI organization. The user clarified that `report-qa` meetings should work as a Q&A format where the user asks questions and participating AI agents answer. The repository was updated so meetings support multiple agendas, use richer review lenses, preserve richer front matter, and follow a standard automation flow: create an `mtg` branch and minutes draft at the start, then finalize, commit, push, and return to the original branch at the end.

The meeting also resulted in concrete implementation work beyond process changes. Local runnable versions of the `research`, `marketing/analytics`, `reporting`, and `dev` agents were added together with a local harness that executes the baseline workflow from a request JSON. Finally, the durable meeting workflow artifacts were standardized in English so future humans and AI tools interpret the process consistently.

## Context

The user ran an extended working session to shape the repository's meeting operating model. The discussion started from `initial-qa` and expanded into process design for `report-qa`, multi-agenda meeting handling, organizational interpretation, review standards, minutes metadata, and automated git workflow. The user also requested implementation work in parallel: build the currently spec-only agents, add harness engineering, ensure commits are actually created, require the branch to return to `main` after commit, and standardize meeting-facing text in English.

## Discussion

### User

- `report-qa` should mean that the user asks questions and AI agents answer.
- A single meeting should be able to handle multiple distinct agendas.
- The currently spec-only AI agents should be implemented.
- Harness engineering should be implemented.
- The assistant should also handle `git add` and `git commit`.
- AI review should explicitly include the user's review lens, the lens of a world-class engineering organization, and the lens of an elite strategy consulting firm.
- The repository should clearly document that the user is the CEO and each AI agent is one employee in an anthropomorphized company model.
- Minutes should include a datetime-style timestamp in front matter.
- Meeting metadata selected at the start, such as meeting type and participants, should be required in front matter.
- When a meeting is committed, the branch should return to `main`.
- The durable meeting workflow, wizard labels, and auto-generated meeting prompts should be in English.

### PM

- The meeting workflow should minimize operator ambiguity at both start and finish.
- The meeting process should make branch ownership, metadata, and finalization steps explicit so the user does not need to restate them each time.
- The anthropomorphized organization model should be documented once and then reused consistently across workflows and reviews.

### Dev

- Implemented local Go agent runtimes for `research`, `marketing/analytics`, `reporting`, and `dev`.
- Implemented a local harness that executes the baseline presentation feedback workflow from request JSON.
- Replaced the placeholder Go CLI dependency on `cobra` with a stdlib-only CLI and added local `agent` and `workflow` commands.
- Added meeting automation so `start-meeting.sh` creates the `mtg` branch and minutes draft automatically.
- Added `finalize-meeting.sh` and `bin/mtg-finalize` so the end-of-meeting flow can update minutes status, commit changes, push with `--set-upstream`, and switch back to the branch recorded in front matter.
- Updated `create-minutes.sh` so new minutes files include required YAML front matter, including ISO 8601 `timestamp` and `started_from_branch`.
- Standardized meeting-facing prompts and durable meeting workflow docs in English.

### Ops

- The meeting process should not rely on memory for git hygiene.
- Start-of-meeting automation should create the dedicated branch and draft minutes immediately.
- End-of-meeting automation should update status, stage everything, commit, push, and return to the original branch.
- Network-dependent steps such as `git push --set-upstream` and GitHub issue / PR creation remain operational dependencies and should be treated as environment-sensitive.

### Reviewer

- The process is materially more robust than before because it now aligns documentation, scripts, and organizational semantics.
- The local harness is a valid first delivery because it proves contracts and workflow sequencing without requiring full distributed orchestration.
- The remaining gaps are mainly production concerns: remote execution, persistence, and live validation of networked git/GitHub operations.

## Review

- CEO perspective:
- The requested direction was implemented: meetings now have clearer semantics, richer metadata, explicit review lenses, and stronger git automation.
- World-class engineering perspective:
- Converting the workflow from convention into scripts and contract-checked artifacts is the correct move. The local harness is credible as a first operational baseline.
- Elite strategy consulting perspective:
- The operating model is now clearer, more repeatable, and easier for future contributors and AI tools to interpret. Decision rights and organizational metaphor are materially less ambiguous.
- Verdict: approved-with-conditions
- Conditions:
- Networked end-of-meeting steps such as `git push --set-upstream`, GitHub issue creation, and PR creation still depend on runtime environment and credentials.
- The production path beyond the local harness is intentionally still open.

## Decisions

- `report-qa` meetings are defined as a format where the user asks questions and participating AI agents answer.
- A single meeting may handle multiple agendas, but `Current Focus` should identify the one currently being worked on.
- The baseline workflow's spec-only agents should have local runnable implementations in the repository.
- Harness engineering should start as a local workflow runner that validates stage sequencing and artifact contracts.
- The repository documents an anthropomorphized organization model in which the user is the CEO and each AI agent is one employee.
- AI review should explicitly consider the user's review lens, world-class engineering standards, and elite strategy consulting standards.
- Minutes must include rich YAML front matter with required start-of-meeting metadata, including ISO 8601 `timestamp`.
- Meeting automation should create the meeting branch and minutes draft at the start of the meeting.
- Meeting finalization should update the minutes, commit changes, push the meeting branch with `--set-upstream`, and return to the recorded original branch.
- Durable meeting workflow artifacts, prompts, and wizard-facing labels should be in English.

## Open Questions

- How far the local harness should evolve toward a production runtime such as a Temporal-backed executor
- When to add persistence and remote agent execution to the harness
- How aggressively GitHub issue creation and PR opening should be automated beyond the current helper scripts
- Whether older historical minutes should also be migrated into the new front matter and English workflow standard

## Parking Lot

- Detailed production orchestration design beyond the local harness
- Broader migration of older minutes files and historical process artifacts
- Additional automation around reviewer assignment, issue labeling, and PR opening

## Action Items

- Owner: Codex
- Task: Keep the meeting workflow automation and minutes governance changes committed and documented.
- Due: completed in this meeting

- Owner: User
- Task: Decide whether to prioritize GitHub issue / PR automation, harness productionization, or migration of older minutes next.
- Due: TBD

## References

- [README.md](README.md)
- [docs/organization-model.md](../organization-model.md)
- [docs/minutes/MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [docs/minutes/README.md](README.md)
- [docs/minutes/template.md](template.md)
- [docs/minutes/meeting-start-prompt.md](meeting-start-prompt.md)
- [docs/minutes/meeting-end-prompt.md](meeting-end-prompt.md)
- [scripts/utils/start-meeting.sh](../../scripts/utils/start-meeting.sh)
- [scripts/utils/create-minutes.sh](../../scripts/utils/create-minutes.sh)
- [scripts/utils/finalize-meeting.sh](../../scripts/utils/finalize-meeting.sh)
- [orchestrator/internal/agents/types.go](/home/yunai/working/org/orchestrator/internal/agents/types.go)
- [orchestrator/internal/harness/executor.go](/home/yunai/working/org/orchestrator/internal/harness/executor.go)
