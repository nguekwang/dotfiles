---
title: separate shell scripts
meeting_name: separate shell scripts
topic: separate-shell-scripts
date: 2026-03-15
timestamp: 2026-03-15T18:12:00+09:00
tool: Codex
meeting_type: general
participants: all
objective: Create document to organize long-line program files into separated, optimized files like onion-architecture
constraints: None
started_from_branch: main
branch: mtg/2026-03-15-separate-shell-scripts
status: final
---

# Meeting: separate shell scripts

## Agenda

- Define what "separate shell scripts" means in this repo
- Propose a shell-oriented layered structure analogous to onion architecture
- Identify concrete refactor targets and migration rules

## Current Focus

- Document a practical structure for splitting long shell programs into smaller, optimized files without breaking CLI entrypoints

## Summary

The meeting focused on how to break long shell programs into smaller files with clearer boundaries and lower coupling. The main example in the current repository is [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh), which currently mixes terminal UI, participant parsing, prompt generation, branching, minutes creation, and model launching in one file. The working direction is to keep thin executable entrypoints and move reusable logic into focused shell libraries grouped by responsibility. The shell equivalent of onion architecture is interpreted here as dependency direction: CLI and infrastructure details stay at the outside, while stable domain rules and workflow orchestration stay toward the center. That direction is now captured in [`docs/architecture/shell-script-separation.md`](../architecture/shell-script-separation.md).

## Context

The stated objective is to create a document that organizes long-line program files into separated, optimized files "like onion-architecture." There are relatively few shell scripts in this repository, but one script is significantly larger than the rest: [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh). That makes the meeting concrete: the document should describe a repeatable structure that can be applied first to meeting automation scripts, then to other shell entrypoints if needed.

## Discussion

### User

- Requested a general meeting to create documentation for separating long shell program files into optimized, layered files.
- Required role-based discussion, running-note diffs, Parking Lot handling, and a Markdown final format.

### PM

- The deliverable should be a practical repo document, not an abstract architecture essay.
- Success means contributors can decide where new shell logic belongs and when a script has become too large to keep monolithic.
- The first audience is maintainers of meeting-related utilities, because that is where the current complexity is concentrated.

### Dev

- A useful shell adaptation of onion architecture is to separate code into thin entrypoints, `domain` rules, `app` orchestration, and `infra` adapters.
- In the current code, [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh) mixes terminal prompting, participant handling, prompt construction, workflow orchestration, and model launching.
- The strongest split candidates are terminal prompting, participant parsing, prompt construction, model launching, and the top-level start-meeting workflow.
- Shared helpers should be sourced rather than duplicated across [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh), [`scripts/utils/finalize-meeting.sh`](../../scripts/utils/finalize-meeting.sh), and [`scripts/utils/close-meeting.sh`](../../scripts/utils/close-meeting.sh).

### Ops

- Shell refactors should preserve portability, debuggability, and failure visibility.
- Modules that call `git`, write files, or launch external CLIs should be clearly marked as infrastructure-facing.
- The guidance should include operational guardrails: `set -euo pipefail`, consistent quoting, explicit return codes, `shellcheck`, and `shfmt`.

### Reviewer

- "Onion architecture" should be translated carefully for shell; a direct copy of object-oriented layering would be overdesigned.
- The correct tradeoff is thin entrypoint plus a few cohesive libraries, not dozens of tiny files.
- Refactoring should proceed incrementally so behavior remains stable while responsibilities are extracted.

## Review

- CEO perspective: use a small number of clear conventions so maintainers can refactor incrementally without stopping delivery.
- World-class engineering perspective: separate policy, orchestration, and side-effecting integrations so each script has a single reason to change.
- Elite strategy consulting perspective: start with the largest script, extract reusable seams, and define a migration rule that can be repeated.
- Verdict: approved-with-conditions

## Decisions

- The document should frame shell "onion architecture" as dependency direction, not class-style layering.
- Long shell programs should be split into thin CLI entrypoints plus sourced modules grouped by `domain`, `app`, and `infra` responsibility.
- The first exemplar and migration target is [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh).
- Refactoring should be incremental: preserve entrypoint behavior while extracting one cohesive responsibility at a time.
- The guidance should explicitly warn against over-fragmentation and keep file counts justified by responsibility boundaries.
- The repository now has an initial architecture note at [`docs/architecture/shell-script-separation.md`](../architecture/shell-script-separation.md).

## Open Questions

- Where should shared shell libraries live in this repository: under `scripts/lib/`, `scripts/utils/lib/`, or another path aligned with existing conventions?
- Should the final guidance prescribe a hard size threshold for extraction, such as line count or number of responsibilities?
- Should extracted shell modules gain tests, and if so, should the repository use `bats` or a lighter validation approach?

## Parking Lot

- Whether the same layered guidance should also be applied to non-shell automation in the repository

## Action Items

- Owner: all
- Task: decide the preferred library path for shared shell modules before implementation starts
- Due: before implementation

- Owner: all
- Task: choose whether to adopt the proposed `scripts/lib/{domain,app,infra}` structure as-is or adjust it to fit existing repository conventions
- Due: before implementation

- Owner: all
- Task: pick the first concrete refactor slice for [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh), starting with either domain helpers or terminal UI helpers
- Due: next implementation meeting

## References

- [docs/architecture/shell-script-separation.md](../architecture/shell-script-separation.md)
- [scripts/utils/start-meeting.sh](../../scripts/utils/start-meeting.sh)
- [scripts/utils/finalize-meeting.sh](../../scripts/utils/finalize-meeting.sh)
- [scripts/utils/close-meeting.sh](../../scripts/utils/close-meeting.sh)
- [docs/minutes/MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
