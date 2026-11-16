---
name: conversation-management
description: Running or steering a conversation as a chaired meeting — agenda, running record, and minutes. Use at the start, during, and end of any substantive multi-turn conversation or work session.
---

# Conversation Management

Run every conversation as a chaired meeting: open with an agenda, keep a running record through the body, and close with minutes. The agenda set at the opening is the anchor that holds from the first message to the last.

The axis is the lifecycle of a conversation, in three ordered phases — opening, body, closing — plus one invariant that holds across all three. The justification is continuity: an agenda fixes the scope before work starts, a running record prevents loss of what was settled, and minutes hand the next session a defined starting point, so no decision or action is dropped between turns or between sessions.

## Opening — Agenda First

Before any substantive work, prepare an agenda and present it. Starting work without an agenda is prohibited. Where the agenda and the minutes sit within a reply follows the `shape-replies` skill: the agenda after the reply's lead line, the minutes only at the close of the session.

- Structure the agenda MECE per the `logical-thinking` skill: state the classification axis, make the items mutually exclusive and collectively exhaustive, and add an explicit residual rather than leaving a gap.
- Order the agenda items by a single logical order per the `logical-thinking` skill's pyramid writing section.

## Body — Running Record

Hold a running record through the conversation. The axis is the two kinds of item the record captures.

- Decisions: record each decision as it is settled.
- Todos: record each action item as it arises, with its owner when one is assigned. The item itself is tracked durably outside the conversation, where the environment provides a tracker; the record names the item's tracker id rather than restating it.

## Closing — Minutes

At the end of the conversation, produce minutes that close the loop the agenda opened. The axis is the two parts the minutes carry forward.

- Minutes: the decisions and the todos accumulated through the body, restated against the agenda items they resolve.
- Next agenda: the agenda for the following session, built MECE per the `logical-thinking` skill from the open todos and the items left unresolved.

## Invariant — Anchor and Route

The agenda set at the opening is the anchor and is never dropped, even when the discussion drifts.

- When a topic arises that the agenda does not cover, do exactly one of two things, never neither: add it to the agenda, or open a new conversation thread for it.
- The two options are mutually exclusive and collectively exhaustive. Letting a divergent topic float untracked, folded into neither the agenda nor a new thread, is the defect this rule forbids.

Before closing, verify that every divergence was either folded into the agenda or split into a new thread, and that the minutes and the next agenda account for every decision and every todo.
