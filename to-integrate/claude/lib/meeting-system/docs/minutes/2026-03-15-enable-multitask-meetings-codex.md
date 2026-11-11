---
title: enable multitask meetings
meeting_name: enable multitask meetings
topic: enable-multitask-meetings
date: 2026-03-15
timestamp: 2026-03-16T00:28:22+09:00
tool: Codex
meeting_type: general
participants: all
objective: Enable multitask meeting especially in a single screen with several terminal sessions
constraints: None
started_from_branch: main
branch: mtg/2026-03-15-enable-multitask-meetings
status: final
---

# Meeting: enable multitask meetings

## Agenda

- Define what "multitask meetings" means in this repository's meeting workflow
- Determine how a single-screen, multi-terminal working style should map to meeting state and minutes
- Decide the minimum workflow and tooling changes needed to support parallel meeting subthreads without losing control

## Current Focus

- Define the operating model for one meeting spanning several terminal sessions on a single screen

## Summary

This meeting defined the intended operating model for multitask meetings in this repository. The conclusion was that multitask support should extend the existing single-meeting workflow rather than introduce a separate meeting type or multiple competing minutes artifacts.

The proposed model keeps one canonical `mtg/*` branch and one canonical minutes file, while allowing several terminal sessions to work in parallel on labeled subthreads. Governance stays simple by requiring one explicit `Current Focus` at a time and by treating other parallel work as supporting subthreads rather than independent meetings.

## Context

The repository already supports structured meetings with one branch and one minutes draft. That is sufficient for sequential work but under-specified for a practical setup where one operator may keep several terminal sessions open on a single screen. The central design question was how to preserve note integrity, decision quality, and branch hygiene without introducing a heavy coordination system.

## Discussion

### User

- Requested support for multitask meetings, especially for a single-screen environment with several active terminal sessions.

### PM

- The user need is higher throughput during meetings without fragmenting decision records.
- The workflow should remain legible to a single operator and should not require a separate artifact per subthread unless the topic truly diverges.

### Dev

- The current repository model of one `mtg/*` branch and one minutes file is a strong base and should be preserved.
- A practical extension is to allow multiple terminal sessions to operate on explicit subthreads while keeping one shared `Current Focus`.
- Additional automation, if any, should focus on note coordination and workflow clarity rather than a complex orchestration layer.

### Ops

- The main risk in multitask meetings is conflicting edits to the minutes file and loss of canonical state.
- The safest default is one canonical minutes artifact plus lightweight rules for ownership and update flow.
- Multi-session work should not weaken the expectation that the final minutes, issues, and PR all come from one `mtg/*` branch.

### Reviewer

- The proposal is directionally correct as long as it avoids overengineering.
- The right bar is controlled parallelism with explicit ownership, not unconstrained concurrent authorship.

## Review

- CEO perspective:
- The workflow extension is worthwhile if it improves operator throughput without producing fragmented decision records.
- World-class engineering perspective:
- The repository should preserve one canonical meeting artifact and add only the minimum rules needed for parallel work.
- Elite strategy consulting perspective:
- Throughput increases only matter if they preserve decision quality and traceability; the proposed model does that.
- Verdict: approved-with-conditions
- Conditions:
- Keep one canonical minutes file and one explicit `Current Focus`.
- Treat parallel work as labeled subthreads unless the meeting truly splits into separate topics.

## Decisions

- A multitask meeting should still be one canonical meeting with one `mtg/*` branch and one minutes file.
- Multiple terminal sessions may contribute in parallel, but the meeting should maintain one explicit `Current Focus` at a time.
- Parallel work should be represented as labeled subthreads or workstreams rather than separate meetings unless the topic truly diverges.
- The operational priority is controlled coordination and minutes integrity, not full concurrent editing freedom.

## Open Questions

- How subthreads should be named and reflected in the minutes structure
- Whether helper scripts should enforce a lock, append-only scratchpad, or another coordination mechanism for concurrent note updates
- Whether each terminal session should declare a role or workstream explicitly at start

## Parking Lot

- Whether multitask meeting support should eventually include explicit worktree or session registration

## Action Items

- Owner: Codex
- Task: Propose a concrete multitask meeting operating model for several terminal sessions, including state ownership and minutes update rules.
- Due: 2026-03-16

- Owner: User
- Task: Decide whether the next step should be workflow guidance only, lightweight script support, or fuller automation for concurrent meeting work.
- Due: TBD

## References

- [docs/minutes/MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [docs/minutes/README.md](README.md)
- [docs/minutes/meeting-start-prompt.md](meeting-start-prompt.md)
- [docs/minutes/meeting-end-prompt.md](meeting-end-prompt.md)
