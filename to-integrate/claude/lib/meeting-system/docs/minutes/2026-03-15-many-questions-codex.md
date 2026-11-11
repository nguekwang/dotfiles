---
title: many-questions
meeting_name: many-questions
topic: many-questions
date: 2026-03-15
timestamp: 2026-03-15T13:08:39+09:00
tool: Codex
meeting_type: report-qa
participants: all
objective: Ask many things on org management
constraints: None
started_from_branch: main
branch: mtg/2026-03-15-many-questions
status: final
---

# Meeting: many-questions

## Agenda

- Q&A on org management topics raised by the user
- agenda1 ルールベース機構とAI機構の峻別
- agenda2 複数MTGの同時実施を可能にする
- agenda3 `mtg` wizard のブランチ名入力を kebab-case に寄せる
- agenda4 `mtg` wizard の説明文を短くする
- agenda5 `gh issue create` のドキュメント化と shell script 化
- agenda6 `docs/` ディレクトリの MECE な再編案
- agenda7 議事録リンクをローカルパスではなく GitHub URL に統一
- agenda8 ルールベース処理を `/bin/sh` shell script に統一
- agenda9 議事録を raw log 型と structured summary 型の 2 種類に分ける

## Current Focus

- agenda3-9 の結論整理と agenda8 の Bash 統一決定

## Summary

- Meeting opened in report-QA mode for org management questions.
- Running notes initialized on the meeting branch.
- User raised four product and workflow topics around meeting orchestration and `mtg` wizard UX.

## Context

- Meeting type: report-qa
- Purpose: Ask many things on org management
- Working mode: user asks questions, agents answer from explicit roles

## Discussion

### User

- Opened meeting and provided operating rules.
- Asked for opinions on four separate agenda items related to architecture and `mtg` command behavior.
- Requested immediate GitHub issue creation for the action items.
- Requested a clear comparison between branch-only and worktree-based concurrent meetings.
- Requested multiple implementation proposals for agenda1 aligned with org policy.
- Asked how to mitigate the operational drawbacks of `git worktree`.
- Clarified the desired agenda1 end-state: AI agents should correctly execute shell-script and API tools so users do not need to manually remember commands or API keys.
- Added agenda5-9 covering issue automation docs/scripts, docs hierarchy, GitHub URLs in minutes, `/bin/sh` standardization, and dual-format minutes.
- Asked for the downsides of standardizing rule-based processing on `/bin/sh`.
- Decided to standardize rule-based processing on Bash instead of `/bin/sh`.
- Requested faster convergence on the remaining agendas.
- Confirmed agenda3-9 as decided.
- Requested `endmtg` to auto-create GitHub issues from confirmed next actions.
- Requested minutes creation to use template copy semantics rather than ad hoc generation.

### PM

- PM: ready to answer org-management questions with prioritization and execution lens.
- agenda1: support clearer product boundary between deterministic tooling and AI decision layers.
- agenda2: support parallel meetings if isolation, naming, and merge-back workflow stay simple.
- agenda3: support automatic kebab-case normalization because it reduces user error in branch naming.
- agenda4: support shortening wizard copy if essential implications remain visible.

### Dev

- Dev: ready to answer process, delivery, and engineering-organization questions.
- agenda1: separation should be explicit in code boundaries and naming, not just conceptual.
- agenda2: concurrent meetings are feasible if each meeting owns an isolated branch and minutes file.
- agenda3: implement slugification at input normalization, not by expecting manual formatting.
- agenda4: shorten copy, but keep one-line consequence hints near irreversible choices.

### Ops

- Ops: ready to answer operating cadence, ownership, and reliability questions.
- agenda1: clearer separation improves observability, auditability, and incident handling.
- agenda2: parallel meetings increase branch management overhead; naming and cleanup policy are required.
- agenda3: auto-normalization reduces branch creation failures and support overhead.
- agenda4: less wizard text improves throughput if defaults remain safe and discoverable.

### Reviewer

- agenda1: risk is ambiguous accountability if AI-triggered actions still appear as "rule-based" outcomes.
- agenda2: risk is operational sprawl if multiple `mtg/*` branches are left open without review discipline.
- agenda3: risk is surprising input mutation unless previewed before confirmation.
- agenda4: risk is removing context that prevents user mistakes; compress, do not erase.

## Review

- CEO perspective:
- World-class engineering perspective:
- Elite strategy consulting perspective:
- Verdict: approved / approved-with-conditions / needs-revision

## Decisions

- Use explicit role labels in answers.
- Maintain running minutes in this draft and surface only diffs in chat updates.
- No implementation decision yet on agenda1-4.
- Action Items should be converted into GitHub issues during the meeting, not deferred.
- agenda8 is redefined from `/bin/sh` standardization to Bash wrapper-script standardization.
- agenda3 is decided: meeting names are slugified automatically with preview.
- agenda4 is decided: the wizard is shortened and detailed guidance moves to docs/help.
- agenda5 is decided: GitHub issue creation is standardized behind Bash wrappers.
- agenda6 is decided: `docs/` taxonomy is fixed before file moves.
- agenda7 is decided: minutes embed GitHub URLs instead of local paths.
- agenda8 is decided: rule-based processing is standardized on Bash wrapper scripts.
- agenda9 is decided: meeting records are separated into raw and structured-summary forms.
- `endmtg` should auto-create issues from Action Items by default.
- Minutes generation should start from a copied template.

## Open Questions

- For agenda1, where should the system boundary be enforced: UX, command layer, or execution engine?
- For agenda2, should concurrent meetings be one worktree each, or branch-only in one workspace?
- For agenda3, should branch-name normalization be silent or shown as a preview?
- For agenda4, what minimum guidance must remain in the wizard?
- For agenda5, should issue creation support one issue per action item or a single roll-up issue?
- For agenda6, what top-level `docs/` taxonomy best fits current and expected growth?
- For agenda7, should minutes prefer permalink URLs, branch URLs, or PR URLs?
- For agenda8, how strict should `/bin/sh` compatibility be for existing Bash-heavy scripts?
- For agenda9, should the two minutes variants live in one file with sections or as separate files?

## Parking Lot

- None yet.

## Action Items

- Define and implement `mtg` wizard slugification so meeting-name-derived branch topics are normalized to kebab-case with preview before confirmation. GitHub issue: #9
- Compress `mtg` wizard explanatory copy to a concise form while preserving essential risk and consequence hints. GitHub issue: #10
- Decide the concurrency model for multiple meetings by comparing branch-only and `git worktree`-based execution, then codify the supported workflow. GitHub issue: #11
- Propose an explicit architecture policy for separating rule-based mechanisms from AI mechanisms, including naming, logging, ownership, and failure classification. GitHub issue: #12

## References

- TBD
- org#9
- org#10
- org#11
- org#12
