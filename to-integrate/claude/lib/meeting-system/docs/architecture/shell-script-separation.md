# Shell Script Separation

This document defines how to split long shell programs into smaller files in this repository.

The goal is not to force object-oriented design onto shell. The goal is to keep shell entrypoints readable, isolate side effects, and make shared behavior reusable across scripts.

## Core Idea

Use a shell-friendly version of onion architecture based on dependency direction:

- Outer layers handle CLI arguments, terminal interaction, filesystem writes, git commands, and external process execution.
- Inner layers hold stable workflow rules and domain logic.
- Dependencies should point inward. Domain logic must not depend directly on terminal UI, `git`, or model-specific launch commands.

For shell, this usually means:

- keep executable scripts thin
- source a small number of focused libraries
- separate pure-ish logic from side-effecting helpers

## Recommended Structure

When a shell script becomes multi-purpose, split it like this:

```text
bin/
  open-meeting

scripts/
  utils/
    start-meeting.sh
    review-meeting-branch.sh
  lib/
    domain/
      meeting.sh
      participants.sh
    app/
      start-meeting.sh
      review-meeting-branch.sh
    infra/
      git.sh
      prompt_ui.sh
      minutes.sh
      model_launch.sh
```

Use these responsibilities:

- `bin/` or script entrypoints
  Parse CLI input, source modules, call one top-level function, exit with its status.
- `scripts/lib/domain/`
  Stable rules and transformations such as slug creation, meeting-type validation, participant normalization, and file-name conventions.
- `scripts/lib/app/`
  Workflow orchestration such as "start a meeting", "finalize a meeting", or "open a meeting PR".
- `scripts/lib/infra/`
  Side-effecting adapters for terminal prompts, git commands, file creation, and launching external tools.

## Dependency Rules

Apply these rules consistently:

- Entry points may depend on any library layer.
- `app` may depend on `domain` and `infra`.
- `infra` may depend on `domain` only when it needs shared formatting or validation helpers.
- `domain` must not depend on `app`, `infra`, terminal state, `git`, or external CLIs.
- Do not let model-specific launch logic leak into general workflow logic.

This keeps high-level workflow readable while containing shell-specific side effects.

## Extraction Heuristics

Split a shell script when one or more of these are true:

- It has more than one clear responsibility.
- It mixes terminal UI, business rules, and external process execution.
- Multiple scripts duplicate the same helper logic.
- The main execution path is hard to read without scrolling through helper details.
- Changes in one area regularly risk regressions in unrelated behavior.

Do not split just to reduce line count. Avoid over-fragmentation.

As a rule of thumb:

- keep the entrypoint under roughly 80-120 lines when possible
- keep each sourced library cohesive around one responsibility
- prefer a few meaningful modules over many tiny files

## Shell-Specific Design Rules

- Keep `set -euo pipefail` in executable scripts.
- Quote expansions unless unquoted behavior is intentional.
- Use functions for reusable logic; avoid copy-paste blocks.
- Prefer returning status codes over calling `exit` deep inside sourced libraries.
- Keep output formatting in UI/infrastructure helpers, not in domain logic.
- Name files by responsibility, not by generic labels like `helpers.sh`.
- Run `shellcheck` and `shfmt` on refactored scripts.

## Example: `start-meeting.sh`

[`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh) currently combines several concerns:

- usage text and CLI parsing
- interactive terminal prompting
- participant discovery and validation
- meeting topic normalization
- prompt construction
- branch and minutes setup
- model process launching

That is a good candidate for separation.

A target split could look like this:

```text
scripts/utils/start-meeting.sh
scripts/lib/domain/meeting.sh
scripts/lib/domain/participants.sh
scripts/lib/app/start-meeting.sh
scripts/lib/infra/prompt_ui.sh
scripts/lib/infra/minutes.sh
scripts/lib/infra/model_launch.sh
scripts/lib/infra/git.sh
```

With responsibilities like:

- `scripts/utils/start-meeting.sh`
  Entry point only. Parse flags, source modules, call `start_meeting_main "$@"`.
- `scripts/lib/domain/meeting.sh`
  `slugify_topic`, meeting-type validation, minutes tool label mapping.
- `scripts/lib/domain/participants.sh`
  participant parsing and normalization.
- `scripts/lib/app/start-meeting.sh`
  assemble the workflow: collect inputs, prepare branch, create minutes, build prompt, launch model.
- `scripts/lib/infra/prompt_ui.sh`
  terminal-only interactions such as menus and prompts.
- `scripts/lib/infra/minutes.sh`
  create minutes file paths and call existing minutes creation utilities.
- `scripts/lib/infra/model_launch.sh`
  launch `claude`.
- `scripts/lib/infra/git.sh`
  current branch lookup and branch-preparation helpers.

## Refactor Sequence

Refactor incrementally:

1. Extract pure domain helpers first.
2. Extract terminal UI helpers second.
3. Extract external command adapters third.
4. Leave the entrypoint until last, then collapse it into a thin wrapper.
5. Verify behavior after each extraction.

This sequence reduces regression risk because the outer side-effecting behavior stays stable while inner logic is moved first.

## What Not To Do

- Do not create dozens of one-function files.
- Do not hide side effects behind vague helper names.
- Do not let sourced files mutate unrelated global variables without clear naming.
- Do not mix prompt rendering with validation rules.
- Do not couple reusable logic to one specific AI model command unless that file is explicitly model-launch infrastructure.

## Initial Scope For This Repository

Apply this pattern first to:

- [`scripts/utils/start-meeting.sh`](../../scripts/utils/start-meeting.sh)
- [`scripts/utils/review-meeting-branch.sh`](../../scripts/utils/review-meeting-branch.sh)
- [`scripts/utils/approve-meeting-branch.sh`](../../scripts/utils/approve-meeting-branch.sh)

Those scripts already form a workflow family and are the most likely place to benefit from shared shell libraries.

## Decision Summary

- Treat shell separation as a dependency-direction problem.
- Keep entrypoints thin.
- Separate domain, workflow, and infrastructure concerns.
- Refactor the meeting scripts first.
