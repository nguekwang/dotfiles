# User Review Lens

The lens is no longer here. It moved into the `branch-review` skill, which is
now the single authority for what a reviewer judges and how a verdict is
reached.

This file held a second fixed lens, used only for meeting branches, while
`branch-review` held another for every other branch. Two fixed lenses cannot
both be fixed: a reviewer following one reached a different verdict than a
reviewer following the other, which is exactly the outcome a fixed lens exists
to prevent. The two were folded together on 2026-09-26, and every item that was
here survives in the merged lens.

| What was here | Where it is now |
| --- | --- |
| Core Standard | `branch-review`, closing sentence of Review Lens |
| 1. Intent Coverage | lens item 1, Intent |
| 2. Explicitness | lens item 4, Explicitness |
| 3. Durable Artifacts | lens item 6, Conformance |
| 4. Traceability | lens item 5, Traceability |
| 5. Simplicity First | lens item 7, Simplicity |
| 6. Safety And Operational Discipline | lens item 3, Safety |
| 7. Quality Bar | Severity and Verdict |
| Approval Rubric | Severity and Verdict |
| Reviewer Output Shape | Severity and Verdict, closing paragraph |
| Secretary Handoff Rule | Re-Review Loop |

What stays specific to a meeting branch is only where the verdict is written:
the `## Review` section of the branch's minutes file, rather than a file under
`.claude/reviews/`. The `branch-review` skill's Record Location section states
both cases, and `bin/review-meeting` is still what writes the meeting one.

Do not restore a lens here. A rule in this file is a rule the reviewer no longer
reads.
