# Meeting Scripts

The shell implementations the `bin/` wrappers and the meeting commands run.

| Script | What it does |
| --- | --- |
| `meeting-branch.sh` | Sourced by the others: names a meeting branch (`yyyy-mm-dd-hh-mm-discuss_<topic>`), recognises one, and reads its topic |
| `start-meeting.sh`, `start-claude-meeting.sh` | The meeting wizard: collects the meeting's name, purpose, and participants, then opens the branch and the minutes |
| `start-meeting-branch.sh`, `start-meeting-worktree.sh` | Open the meeting branch in place or as a linked worktree |
| `create-minutes.sh` | Writes the minutes draft from `docs/minutes/template.md` |
| `list-meeting-worktrees.sh`, `clean-meeting-worktrees.sh` | List the meeting worktrees, and remove those whose branch is merged |
| `review-meeting-branch.sh`, `approve-meeting-branch.sh` | Record a review verdict as a `## Review` section in the minutes, committed on the branch |
