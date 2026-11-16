---
name: rules-feedback
description: Handling user feedback about how the agent operated. Use whenever the user gives feedback on the agent's behavior, style, or output — treat it as a candidate change to the AI operating rule skills and reconcile it before acting.
---

# Feedback Handling

Treat every feedback item as a candidate rule change, and reconcile it with the AI operating rule skills before acting.

- If the feedback is not yet covered by any existing skill, propose an edit that adds it (either to an existing skill, per `rules-structure`, or as a new skill).
- If the feedback contradicts an existing rule, do not resolve the conflict yourself. Show the user the existing rule and the new feedback side by side, and ask which applies:
  1. the new feedback replaces the old rule outright, or
  2. both stand, each governing a different situation — if so, ask what distinguishes those situations.
  Write the edit only after the user answers, encoding their answer rather than a guess.
- Always present the proposed edit. Follow the `config-file-editing` skill: state the target path, distinguish the operation type (add / modify / delete), and explain where, what, and why for each diff unit.
- Apply this check to every feedback item without exception.
