---
title: enable-agents
meeting_name: enable-agents
topic: enable-agents
date: 2026-03-14
timestamp: 2026-03-15T12:24:08+09:00
tool: Codex
meeting_type: general
participants: all
objective: Enable AI Agents
constraints: None
started_from_branch: main
branch: mtg/2026-03-14-enable-agents
status: final
---

# Meeting: enable-agents

## Agenda

- Assess the current agent implementation and enablement state
- Decide what “enabled” means for this repository
- Identify the minimum work needed to make agents runnable and usable

## Current Focus

- Clarify what is usable now versus what is still only specified or scaffolded

## Summary

This meeting is focused on making AI agents operational in the repository, not just documented. The repository already defines agent roles for `research`, `reporting`, `marketing/analytics`, and `dev`, and it includes workflow specifications plus meeting automation around agent participation. However, the current branch state shows a gap between documentation and implementation: the agent role READMEs and workflow spec exist, but the runnable orchestrator and agent runtime surface appear incomplete.

The immediate goal of this meeting is to decide the enablement target and close the highest-value gaps first. At minimum, “enabled” should mean there is a clear execution path from a request to agent-specific output, with documented invocation, explicit ownership across stages, and a reliable local workflow for validation. Based on the current repository state, there is one concrete local workflow available now: presentation generation from structured JSON or Postgres-backed data. By contrast, a true multi-agent runtime or agent CLI surface is not currently available in the visible code.

## Context

The meeting was started on branch `mtg/2026-03-14-enable-agents` with the purpose `Enable AI Agents`. The repository already contains:

- agent role definitions under `agents/`
- a workflow specification in `orchestrator/internal/workflows/org-presentation_feedback_workflow.go`
- meeting automation that treats agents as meeting participants

At the same time, the currently visible code under `orchestrator/` is limited. The CLI entrypoint in `orchestrator/cmd/cli/main.go` is still placeholder-oriented and depends on `cobra`, while the richer runtime files referenced by an earlier minutes document are not present in the working tree. This makes agent enablement an implementation and governance question, not only a documentation task.

## Discussion

### User

- Start a general meeting to enable AI agents.
- Require role-based discussion and running minutes.
- Use participating agent perspectives first, with PM / Dev / Ops / Reviewer as supporting lenses.
- Ask whether AI agents are usable right now and how they can be used.
- Ask whether OpenAI Symphony and Linear can be used, and request that web search default to English-language sources.
- Ask for the organization's views on GitHub Issues versus Linear as the operating system for work tracking.
- Ask whether a split model is workable: Linear as source of truth, with GitHub Issues used only by the development organization for technical discussion and review.
- Decide to limit the conditions under which GitHub Issues may be used.
- State that the CEO will initially join the development loop directly, but over time the development layer should be usable primarily by AI agents.
- Reject all Linear-related decisions and remove Linear as an adopted direction for this meeting.
- Decide to unify work tracking on GitHub Issues.

### Research Agent

- The repository has enough role definitions to describe what evidence-producing work should happen, but not enough visible execution logic to prove that the `research` role can be run end-to-end.
- “Enabled” should require a request contract, source/evidence output contract, and at least one local invocation path that produces reproducible artifacts.
- Right now, research content can be represented inside `docs/ai/sample-request.json`, but there is no separate runnable `research` agent command in the repository.
- A current web check did not verify any public OpenAI product or official integration named `Symphony`; this may be a naming mismatch or a non-public/internal tool.
- For organizational workflow, research work tends to span ambiguous questions, evidence collection, and synthesis; that is easier to manage in a planning system like Linear than in repo-local GitHub Issues alone.
- If GitHub Issues becomes the single system, research and strategy threads will need explicit labeling and templates so they do not get buried under implementation-only work.

### Reporting Agent

- The repo already frames agent collaboration around transforming research and assumptions into decision-ready outputs.
- From a narrative perspective, the main gap is operational credibility: without a runnable path, the agent system remains an organizational sketch rather than an active workflow.
- The currently usable path is the reporting-oriented local deck generator driven by structured input data.
- Linear was discussed as an external option, but that direction has now been explicitly rejected for this meeting.
- With GitHub Issues as the single system, reporting needs a stronger issue taxonomy so decision threads, implementation threads, and review threads remain distinguishable.

### Marketing Analytics Agent

- The current definitions identify expected KPI and prioritization outputs, which is a good contract boundary.
- The missing piece is a live execution path that turns structured inputs into analytics artifacts the downstream reporting layer can consume.
- Analytics assumptions can be passed in through the structured request JSON, but there is no standalone analytics agent invocation path yet.
- Analytics still prefers keeping technical implementation discussion scoped to the development layer, but without relying on Linear as the adopted planning system.
- If GitHub Issues is the only system, labels and issue templates will need to represent business and analytics context explicitly.

### Dev Agent

- Agent responsibilities are documented, and a workflow spec exists, but the present `orchestrator/` tree does not expose a working local harness or agent command surface.
- The repo currently shows a mismatch between documentation/minutes and code reality; that mismatch should be resolved before broader enablement claims are made.
- The concrete runnable command today is `scripts/run_presentation.sh`, not `ai agent ...` or `ai workflow ...`.
- For the future AI-agent-heavy model, any dev-discussion tool should be reserved for cases where durable repo-local technical context materially improves implementation or review quality.
- GitHub Issues as a single system is workable for dev because it keeps execution, code review references, and repository-local context in one place.

### PM

- The meeting should converge on a concrete enablement definition rather than a vague aspiration.
- The most valuable near-term milestone is a local, testable workflow that proves the agents can be invoked in sequence from a structured request.
- PM supports a narrow allowlist for GitHub Issues or any future dev-only discussion layer so the future shift from CEO-in-the-loop to agent-only execution does not require a second process redesign.
- If GitHub Issues is the only system, PM needs naming conventions, labels, and issue types so planning work stays legible.

### Dev

- The workflow spec already defines stage owners and artifact boundaries, which is a good foundation.
- The CLI entrypoint still looks like scaffold code, so enablement likely requires implementation work in `orchestrator/` rather than only editing documentation.
- A minimum viable delivery would be a stdlib-only CLI or similar local runner that can execute named agents and the baseline workflow without external services.
- The current `orchestrator/cmd/cli/main.go` still exposes placeholder `deploy`, `report`, and `marketing` commands and depends on `cobra`; it does not expose agent execution commands.
- Dev recommends avoiding duplicate manual entry. If both systems are used, one must be primary and the other synchronized automatically.
- Dev views a dev-only discussion layer as acceptable friction, not fatal friction, if it is used only when a thread genuinely benefits from code-adjacent discussion or durable technical review notes.
- If GitHub Issues is the only system, the repo should standardize labels and templates instead of trying to preserve a split-model allowlist.

### Ops

- Enablement is incomplete unless the invocation path is explicit, repeatable, and easy to verify locally.
- Meeting automation already handles agent participation semantics well; operational focus should shift to runbooks, commands, and verification for actual agent execution.
- If follow-up automation includes GitHub issue creation or PR opening, those remain environment-sensitive due to network and auth dependencies.
- The local presentation runbook is the only clearly documented operational path for agent-adjacent output generation today.
- The user requested a standing preference to use web verification by default and prioritize English-language sources when browsing is helpful.
- Ops sees the main operational risk as orphaned dev-only issues and drift between official planning state and repo-local discussion. Any issue creation path should remain an exception with explicit criteria so future autonomous agents have a deterministic policy to follow.
- GitHub-Issues-only simplifies operations by removing cross-system drift, but it shifts the burden into stronger conventions for labels, templates, and lifecycle rules.

### Reviewer

- The repository has a coherent agent operating model on paper.
- The main risk is false confidence from documentation that outpaces implementation.
- The meeting should prefer verifiable local execution over ambitious but speculative orchestration design.
- Reviewer sees the main failure mode as dual-entry drift. If both systems are adopted without a strict ownership rule, the organization will lose trust in both.
- Reviewer endorses a narrow allowlist for any dev-only issue layer so the later move from CEO-in-the-loop to mostly agent-only execution remains operationally consistent.
- GitHub-Issues-only is cleaner than a split model as long as issue taxonomy is disciplined enough to separate planning, implementation, and review threads.

## Review

- CEO perspective:
- The repository is close to having a coherent AI operating model, but “enabled” should only be claimed once the agents are actually runnable in a way that supports decision-making work.
- World-class engineering perspective:
- The next step should be to close the contract-to-runtime gap with a minimal but testable local harness.
- Elite strategy consulting perspective:
- The enablement plan should define a narrow first operating capability, prove it, and expand only after the first workflow produces useful output reliably.
- Verdict: pending

## Decisions

- The repository is partially usable now:
- meeting-mode role play and agent-perspective discussion are usable
- local presentation generation from structured inputs is usable
- a real runnable multi-agent orchestrator or agent CLI is not yet usable from the visible codebase
- For this meeting, web searches should default to English-language sources when external verification is needed.
- All Linear-related decisions discussed in this meeting are rejected and should not be treated as adopted policy.
- Work tracking is unified on GitHub Issues.
- The repository should define labels, templates, and issue conventions so GitHub Issues can cover planning, implementation, and review without ambiguity.
- The operating model should still work both while the CEO is directly participating in dev discussions and later when AI agents handle most of the dev-layer workflow.

## Open Questions

- What exact capability should count as “enabled” for closure of this meeting: individual agent commands, a local workflow runner, or a fuller orchestrator?
- Are the agent runtime files referenced by earlier minutes missing from this branch, or were those minutes ahead of the actual code state?
- Should the first implementation target be `ai workflow run presentation_feedback_loop` or explicit per-agent commands such as `ai agent run research`?
- What tool or product name the user intended by `OpenAI Symphony`, since that name was not verified from current public official sources
- What label taxonomy should be standardized for GitHub-Issues-only operation
- Tracking issue: org#3
- What issue template types should be standardized for GitHub-Issues-only operation
- Tracking issue: org#4
- How meeting action items should be mapped to GitHub Issue types
- Tracking issue: org#5
- How planning issues, implementation issues, and review issues should be distinguished inside GitHub
- Related tracking issue: org#6

## Parking Lot

- Remote execution, persistence, and production orchestration beyond local enablement

## Action Items

- Owner: Codex
- Task: Establish the current implementation baseline and identify the minimum code and workflow changes required to make agents locally runnable.
- Due: in this meeting

- Owner: Codex
- Task: Record the currently usable command paths precisely so the user can operate the existing local workflow without assuming full agent enablement.
- Due: in this meeting

- Owner: Codex
- Task: Remove the unadopted Linear-specific operating model artifacts and revert those decisions in the meeting record.
- Due: completed in this meeting

- Owner: Codex
- Task: Propose the minimum GitHub Issues taxonomy and templates needed for a single-system operating model.
- Due: tracked in org#6

- Owner: User
- Task: Decide whether to start with a strict GitHub Issues model.
- Due: tracked in org#7

## References

- [agents/dev/README.md](README.md)
- [agents/reporting/README.md](README.md)
- [agents/research/README.md](README.md)
- [README.md](README.md)
- [docs/runbooks/local-presentation-generation.md](/home/yunai/working/org/docs/runbooks/local-presentation-generation.md)
- [scripts/run_presentation.sh](/home/yunai/working/org/scripts/run_presentation.sh)
- [orchestrator/cmd/cli/main.go](/home/yunai/working/org/orchestrator/cmd/cli/main.go)
- [orchestrator/internal/workflows/org-presentation_feedback_workflow.go](/home/yunai/working/org/orchestrator/internal/workflows/org-presentation_feedback_workflow.go)
- [docs/minutes/2026-03-14-meeting-ops-Codex.md](2026-03-14-meeting-ops-codex.md)
- org#3
- org#4
- org#5
- org#6
- org#7
- https://linear.app/integrations/chatgpt
- https://linear.app/integrations/codex-mcp
- https://linear.app/docs/mcp
- https://help.openai.com/en/articles/12526595-linear-synced-connector
