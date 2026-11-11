---
name: approve-meeting
description: Record approval for an eligible meeting branch (rv/approve role)
disable-model-invocation: true
---

# /approve-meeting

Act as the `rv/approve` agent (see `.claude/lib/meeting-system/agents/rv/approve/CLAUDE.md`). Do not re-judge the branch's substance — only record approval, and only if all of the following hold:

Usage: `/approve-meeting <meeting-branch>`

1. Branch $ARGUMENTS[0] is a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`) and is not already merged into `main`.
2. The reviewer agent's verdict (from `/review-meeting`) was `approve`.

If eligible, run `.claude/lib/meeting-system/bin/approve-meeting $ARGUMENTS[0]` (or `.claude/lib/meeting-system/scripts/utils/approve-meeting-branch.sh $ARGUMENTS[0]`). This appends a `## Review` (decision: approve) section to the branch's minutes file and commits it on the branch itself — this command records the local approval and does not submit a GitHub approval or authorize merging. If any eligibility check fails, report exactly why and do not approve.

Branch: $ARGUMENTS[0]
