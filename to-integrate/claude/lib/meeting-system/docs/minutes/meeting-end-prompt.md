# Meeting End Prompt

Use the following at the end of a meeting to converge the running memo into final minutes.

If the user says the meeting is over in plain language without using this template, finalize the minutes and prepare the selected integration path. Meeting closure and review approval do not authorize merging; obtain explicit user authorization.

How to use it:

1. Send this template when you want to end the meeting.
2. Add detail in `<extra-instruction>` if needed.
3. Review the final draft produced by the AI and request only small fixes if necessary.
4. Save the resulting Markdown into `docs/minutes/`.
5. Check that Action Items are detailed enough to stand on their own as the durable record — there is no separate GitHub issue.
6. Prepare integration under `rules-version-control`. Proceed to merge only after explicit user authorization, preserving all required reviews.

```text
End the meeting here.

Using the running memo so far, produce the final meeting minutes in Markdown.

Requirements:
- Include YAML front matter and fill in `title`, `meeting_name`, `topic`, `date`, `timestamp`, `tool`, `meeting_type`, `participants`, `objective`, `constraints`, `started_from_branch`, `branch`, and `status`.
- Organize the content around the Current Focus.
- Always include Decisions, Open Questions, Parking Lot, and Action Items.
- Remove duplicates and intermediate notes, keeping only the final decisions.
- Make Action Items as explicit as possible about owner and due date.
- Write Action Items at a granularity that stands on its own, with clear purpose and deliverable per item — they stay recorded in this file, not in a separate issue.
- Format the result so it is easy to save.
- After producing the final minutes, commit them on the meeting branch and follow the selected integration path in `rules-version-control`. Integrate only after merging is explicitly authorized. Preserve review requirements and the prohibition on force-pushing for either path.

Additional Instruction:
- <extra-instruction>
```

## Example

```text
End the meeting here.

Using the running memo so far, produce the final meeting minutes in Markdown.

Requirements:
- Include YAML front matter and fill in `title`, `meeting_name`, `topic`, `date`, `timestamp`, `tool`, `meeting_type`, `participants`, `objective`, `constraints`, `started_from_branch`, `branch`, and `status`.
- Organize the content around the Current Focus.
- Always include Decisions, Open Questions, Parking Lot, and Action Items.
- Remove duplicates and intermediate notes, keeping only the final decisions.
- Make Action Items as explicit as possible about owner and due date.
- Write Action Items at a granularity that stands on its own, with clear purpose and deliverable per item — they stay recorded in this file, not in a separate issue.
- Format the result so it is easy to save.

Additional Instruction:
- Mark which Open Questions should move to the next meeting.
```
