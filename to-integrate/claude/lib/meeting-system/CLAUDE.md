---
name: meeting-system
description: Shared scripts, protocol docs, and role docs behind this repository's meeting-branch workflow and AI-Org role model. Backs /open-meeting, /list-meetings, /clean-worktrees, /review-meeting, /approve-meeting, /apply-review-findings, /research-strategy, /write-proposal-narrative, /estimate-impact, /normalize-proposal-feedback, /build-proposal. Not invoked directly — those commands read and run the files under here.
---

# AI-Org — Meeting OS And Agent Roles

The operating assets behind this repository's meeting workflow and its AI-Org
role model. Everything here is read or executed by the slash commands, which are
skills under `.claude/skills/`; nothing in it runs on its own.

The repository is deliberately anthropomorphized as a company:

- the user is the CEO
- each agent is one employee with a defined role
- the repository is the operating system and memory of that organization

See `docs/organization-model.md` for the operating interpretation and the
review model.

## Layout

- `agents/` — one `CLAUDE.md` per role, naming that role's inputs, outputs and
  quality bar. `dev/`, `marketing/analytics/`, `integrator/`, `reporting/`,
  `research/`, `reviewer/`, `rv/approve/`, `secretary/`. The meeting wizard
  reads the agent ids from this directory for its participant selector. A
  directory is a role exactly when its `CLAUDE.md` has a `## Role` heading.
  The matching `/`-command acts as that role.
- `bin/` — command entry points (`open-meeting`, `list-meetings`, `clean-worktrees`, `review-meeting`, `approve-meeting`, `start-claude-meeting`).
  Each is a thin wrapper that execs the matching script under `scripts/utils/`.
  Integration has no wrapper or command: once merging is authorized, the
  branch is merged per the `rules-version-control` skill, so the commit review
  and the branch deletion see each step.
- `scripts/utils/` — the shell implementations behind those wrappers: starting a
  meeting branch or worktree, creating the minutes file from the template,
  and reviewing a meeting branch. `meeting-branch.sh` is sourced by the others and
  is the one place that names a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`). See
  `docs/architecture/shell-script-separation.md` for the wrapper/implementation
  split.
- `docs/minutes/` — `MEETING-PROTOCOL.md` (the protocol every meeting follows),
  `template.md`, the kickoff and close-out prompts, and the meeting history.
  New minutes are written here.
- `docs/review/` — `user-review-lens.md` (what a review judges against) and
  `meeting-branch-review-workflow.md` (how a meeting branch is reviewed and
  integrated).
- `docs/playbooks/`, `docs/runbooks/` — the proposal-deck quality bar, and the
  `PATH` setup for calling `bin/` directly from a shell.

## Usage

Run a meeting through the slash commands (`/open-meeting`, `/review-meeting`, and
the rest), or call `bin/` directly after putting it on `PATH` per
`docs/runbooks/meeting-command-path-setup.md`. Minutes are created relative to
the working directory the meeting starts from, so run the commands from this
directory unless you intend the minutes to land elsewhere.

Integration follows the `rules-version-control` skill. The meeting scripts
support local review and direct `git merge --no-ff` integration; pull requests
and the `gh` CLI are also permitted under that skill. Review requirements and
the prohibition on force-pushing still apply. Meeting closure and review
approval do not authorize merging; obtain explicit user authorization for the
selected integration path.

## Removed Components

Recorded so that a later reader does not go looking for machinery that was
deliberately dropped.

- `ai/claude.toml`, `ai/gemini.json` — old claude/gemini CLI configuration.
- `ai/claude/` — the Claude.ai export-collection RPA (`collect.py`, `main.md`).
- `.opencode/`, `ai/opencode_client.py`, `opencode.json` — opencode commands,
  skills and MCP configuration (a `provider.ollama` block and `notion`/
  `web_search` MCP servers, both already gone below), dropped when the setup
  consolidated on Claude Code.
- `ai/agent.py`, `ai/server.py`, the `ddgs` dependency — a self-built local
  search harness, dropped for insufficient quality.
- `bin/start-opencode-meeting` and its `scripts/utils/` script — opencode-only
  meeting wrappers, replaced by `start-claude-meeting`. Neither file is in the
  tree; only this line records that they existed.
- `ai/notion_mcp_server.py`, `ai/notion_tools.py`, `ai/scheduler.py` — Notion
  integration (goals, progress log, daily summary) and the JST 22:00 poster,
  dropped when Notion itself was dropped.
- `ai/bot.py`, `ai/claude_client.py`, `ai/config.py` and the Python project
  files — the Discord coaching bot. Its persona lives on as
  `.claude/skills/coach-report/SKILL.md`, which is now used interactively.
- `ai/ollama/` — bootstrap script for a separate `~/working/ollama` repository.
- `orchestrator/` (Go), `schemas/`, `tools/marp_exporter/`, `output/demo/`,
  `scripts/run_presentation*.sh`, `scripts/migrate/`,
  `scripts/utils/generate_presentation.py`,
  `scripts/utils/export_request_payload.py` — the presentation generation
  pipeline (Postgres, a vector-index design, a Marp exporter and a Go agent
  harness). `/build-proposal` now runs the same stages in conversation instead.
