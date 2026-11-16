---
name: grill-me
description: Grill the user relentlessly about a plan, decision, or idea until every open decision is settled and nothing is silently assumed - researching first and putting each decision as options with a recommendation, through AskUserQuestion or, when words fail, an HTML sheet the user clicks, drags, or marks up and pastes back - then stopping at a settled summary until the user says go. Use when the user wants to stress-test their thinking, runs /grill-me or any 'grill' trigger phrase, or whenever a request leaves a decision that is the user's to make.
---

# Grill Me

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Put each round through the AskUserQuestion tool, as this user asked: up to four questions per call, the recommended option first and labelled "(Recommended)". When a round holds more than four questions, or the harness has no such tool, format it as text, one block per question, separated by a blank line:

```text
Q1. <question title>
<question body, might be multiple paragraphs, including multiple choices>
推奨：<your recommended answer>

Q2. <question title>
<question body, might be multiple paragraphs, including multiple choices>
推奨：<your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

## Propose, Don't Interrogate

Answering dozens of open questions tires the user, and a tired user nods through the agent's plan. So the agent does the researching, comparing, and recommending, and the user only picks or corrects. The approach is adapted from the "akapen" article landed in `bronze-source/note-masao/`.

- Every question arrives with its basis (the fact, a `file:line`, or a source) and two to four concrete options, the recommendation first. An open-ended question is a last resort, for a decision no option set can cover.
- Choose the medium by what the decision is made of:

| The decision is about | Medium |
| --- | --- |
| A choice that words carry | AskUserQuestion, as above |
| A look or a quantity: layout, size, spacing, timing, a threshold | An HTML artifact with the options drawn side by side or controls (sliders, toggles) to try, ending in a "Copy as prompt" button that writes the chosen values as text to paste back |
| A draft: a document, message, or rule text | An HTML artifact showing the draft itself, where the user marks passages to cut, change, or demote, ending in a button that collects the marks into text to paste back |

- An HTML sheet costs far more tokens than a question, so it is used only when words would fail. Write it to `golden-mart/<yyyymmddhhmmss>-<content>.html` per the `files-and-repository` skill's "Artifact Output", build it per the `artifact-design` skill with a plain template rather than decoration, and publish it as an Artifact so the user can open it from anywhere.
- An unanswered question is not settled by its recommendation. A question the user skipped, deselected, or deferred stays on the frontier and comes back next round.

## Stop at the Settled Summary

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Then post a settled summary and stop:

- every decision, across all rounds, as `Q<n> -> <choice>`;
- the files, documents, or systems the work will touch;
- any assumption still standing.

Do not act on it until the user confirms the summary or says to proceed; a correction revises the summary and it is posted again.
