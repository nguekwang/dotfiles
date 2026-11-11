---
name: apply-review-findings
description: Apply reviewer findings to a rejected meeting branch and prepare it for re-review (secretary role)
disable-model-invocation: true
---

# /apply-review-findings

Act as the `secretary` agent (see `.claude/lib/meeting-system/agents/secretary/CLAUDE.md`).

Usage: `/apply-review-findings <meeting-branch>`

1. Read the `request-changes` findings left by the reviewer agent in the `## Review` section of branch $ARGUMENTS[0]'s minutes file.
2. Convert each blocking finding into a concrete edit and apply the minimum set of changes needed to satisfy the `branch-review` skill's Review Lens. Do not broaden scope beyond the findings unless the user explicitly asks; the `branch-review` skill's Re-Review Loop states the secretary's boundary.
3. Preserve the original meeting intent and existing workflow conventions (see `.claude/lib/meeting-system/docs/minutes/MEETING-PROTOCOL.md`).
4. Commit the fix on the same meeting branch. When updating an authorized pull request, push the reviewed commits to that branch without force-pushing, following the `rules-version-control` skill.
5. Post a concise change summary (what was fixed, per finding) and hand back to `/review-meeting $ARGUMENTS[0]` for re-evaluation.

Branch: $ARGUMENTS[0]
