# Meeting Start Prompt

Use the following as the first message to a CLI AI tool to enter meeting mode cleanly.

How to use it:

1. Fill in placeholders such as `<meeting-name>`.
2. Send the result as the first message of the meeting.
3. Use the AI's first running memo as the starting point for the meeting.

```text
We are now working in meeting mode.

Meeting Name: <meeting-name>
Meeting Type: <meeting-type>
Purpose: <purpose>
Constraints: <constraints>
Participants: <participants>

Working Rules:
- Speak from explicit roles.
- Prioritize the perspectives of participating agents, and use PM / Dev / Ops / Reviewer as supporting lenses when needed.
- Assume the meeting starts on a meeting branch with a minutes draft already created.
- Adjust the depth and output shape to fit the meeting type.
- Maintain running notes during the meeting and show only diffs when updating them.
- Move off-topic threads to the Parking Lot and state the Current Focus before returning to the main topic.
- Always end with Decisions, Open Questions, and Action Items.
- When producing minutes, include YAML front matter and preserve all start-of-meeting metadata as required fields.
- After the meeting, keep Action Items recorded in the minutes and commit the minutes on a meeting branch, then follow the selected direct-merge or pull-request path in `rules-version-control`. Preserve required reviews and obtain explicit user authorization before merging; meeting closure and review approval do not supply it.
- Format the final output as clean Markdown.
```

## Example

```text
We are now working in meeting mode.

Meeting Name: naming-policy
Meeting Type: general
Purpose: Decide the operating policy for IaC-based naming conventions
Constraints: Terraform-centered, spans both Azure and AWS
Participants: all

Working Rules:
- Speak from explicit roles.
- Prioritize the perspectives of participating agents, and use PM / Dev / Ops / Reviewer as supporting lenses when needed.
- Assume the meeting starts on a meeting branch with a minutes draft already created.
- Adjust the depth and output shape to fit the meeting type.
- Maintain running notes during the meeting and show only diffs when updating them.
- Move off-topic threads to the Parking Lot and state the Current Focus before returning to the main topic.
- Always end with Decisions, Open Questions, and Action Items.
- When producing minutes, include YAML front matter and preserve all start-of-meeting metadata as required fields.
- After the meeting, keep Action Items recorded in the minutes and commit the minutes on a meeting branch, then follow the selected direct-merge or pull-request path in `rules-version-control`. Preserve required reviews and obtain explicit user authorization before merging; meeting closure and review approval do not supply it.
- Format the final output as clean Markdown.
```
