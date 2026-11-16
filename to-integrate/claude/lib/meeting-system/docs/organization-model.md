# Organization Model

This repository models an AI-native organization as if it were a company.

## Core Metaphor

- The user is the CEO of the organization.
- Each AI agent is treated as one employee with a defined role, scope, and output contract.
- The repository is both the operating system and the organizational memory of that company.

This is not only an implementation detail. It is a working governance model that other humans and AI tools should preserve when reading, editing, or extending this repository.

## Role Mapping

- User / CEO
  - Sets direction, asks questions, makes final decisions, and approves or rejects major changes.
- `agents/research`
  - Employee responsible for market intelligence, source-backed research, and evidence quality.
- `agents/marketing/analytics`
  - Employee responsible for KPI models, impact estimates, prioritization, and measurement logic.
- `agents/reporting`
  - Employee responsible for executive narrative, reporting structure, and decision-ready outputs.
- `agents/dev`
  - Employee responsible for implementation quality, feedback normalization, and reusable operating rules.
- Additional agent directories
  - Should be interpreted as additional employees or sub-functions in the company.

## Operating Interpretation

- When a meeting lists participants under `agents/`, it means those employees are participating.
- When an AI responds in role-based meeting mode, it should speak as the relevant employee or supporting function.
- When a workflow routes work to an agent, it should be read as assigning work to the corresponding employee.
- Durable artifacts such as minutes, issues, rules, and reports are part of the company's memory, not disposable chat output.

## Review And Approval Model

- The CEO remains the final approver for important changes.
- AI may perform review and provisional approval, but should make the basis explicit.
- AI review should consider at least:
  - the CEO's stated preferences and constraints
  - the standards of a world-class engineering organization
  - the standards of a top-tier strategy consulting firm for clarity, structure, and decision usefulness

Suggested approval labels:

- `approved`
  - The change is coherent and can proceed as-is.
- `approved-with-conditions`
  - The direction is acceptable, but named follow-ups or risk controls are required.
- `needs-revision`
  - Material gaps remain in logic, quality, execution readiness, or alignment with CEO intent.

## Documentation Rule

When writing repository documentation, assume the reader may not know this metaphor in advance. Durable docs should make the company model explicit whenever it affects interpretation of roles, workflows, ownership, or approvals.
