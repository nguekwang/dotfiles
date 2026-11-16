---
name: review-meeting
description: Review a meeting branch against the user review lens and record the verdict (reviewer role)
disable-model-invocation: true
---

# /review-meeting

Act as the `reviewer` agent (see `.claude/lib/meeting-system/agents/reviewer/CLAUDE.md`), evaluating strictly against the `branch-review` skill's Review Lens, which is the single authority for the lens and the verdict — not generic style preference.

Usage: `/review-meeting <meeting-branch> [approve|request-changes]`

1. Confirm branch $ARGUMENTS[0] is a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`) and is not already merged into `main` (per `.claude/lib/meeting-system/docs/review/meeting-branch-review-workflow.md`, only act on such branches).
2. Read the branch's diff against `main` (`git diff main...$ARGUMENTS[0]`) and the affected files.
3. Score it against every item of the `branch-review` skill's Review Lens (Intent, Correctness, Safety, Explicitness, Traceability, Conformance, Simplicity, Evidence, Other), and grade each finding blocking / should-fix / nit per that skill's Severity and Verdict section.
4. Decide a verdict: `approve` only if every hard requirement passes; otherwise `request-changes`, with findings ordered by severity and each pointing to a concrete file, line, or workflow step.
5. If the branch has diverged from a `main` that moved since the branch started, resolve per the "Conflict Resolution Policy" in meeting-branch-review-workflow.md before reviewing further.
6. Record the verdict with `.claude/lib/meeting-system/bin/review-meeting $ARGUMENTS[0] --decision <approve|request-changes>` (use $ARGUMENTS[1] if a decision was already forced by the caller; otherwise use the verdict decided in step 4). This appends a `## Review` section to the branch's minutes file and commits it on the branch itself — this command records the local verdict and does not authorize merging.

Branch: $ARGUMENTS[0]
Forced decision (optional): $ARGUMENTS[1]
