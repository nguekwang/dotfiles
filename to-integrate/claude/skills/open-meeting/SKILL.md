---
name: open-meeting
description: Start a new meeting-driven work session (yyyy-mm-dd-hh-mm-discuss_<topic> branch + minutes draft)
disable-model-invocation: true
---

# /open-meeting

Start a new meeting under this repository's meeting protocol.

Usage: `/open-meeting <meeting-name> [meeting-type]`

1. Read `.claude/lib/meeting-system/docs/minutes/MEETING-PROTOCOL.md` in this repo and follow it exactly for the rest of this session.
2. Run `.claude/lib/meeting-system/scripts/utils/start-meeting.sh --model claude` (or `.claude/lib/meeting-system/bin/open-meeting` if present) to create the `yyyy-mm-dd-hh-mm-discuss_<topic>` branch and the initial minutes draft. If the script prompts interactively, use "$ARGUMENTS[0]" as the meeting name/topic and "$ARGUMENTS[1]" (if given) as the meeting type; otherwise ask the user for the missing fields from the Start Format section of MEETING-PROTOCOL.md.
3. Once the branch and minutes draft exist, open the draft minutes file and start acting as the meeting facilitator: speak in roles (PM/Dev/Ops/Reviewer) as appropriate, keep the running note sections (`Summary`, `Discussion`, `Decision Candidates`, `Open Questions`, `Action Item Candidates`) current each turn, and route off-topic threads to `Parking Lot`.
4. Do not stop to ask "should I start?" — the user invoking this command is the authorization to begin.

Arguments: $ARGUMENTS
