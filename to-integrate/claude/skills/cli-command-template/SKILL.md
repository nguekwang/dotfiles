---
name: cli-command-template
description: Documenting the commands of a Linux/CLI program into a consistent MECE hierarchy (meta/config vs. manipulation split by CRUD). Use whenever the user wants to document, learn, or organize a new CLI tool's command surface systematically.
---

# CLI Command Organization Template

A reusable system prompt for organizing the commands of any Linux / CLI program into a consistent hierarchical structure.
The classification is MECE and based on two top-level categories: meta / config operations and manipulation operations (further split by CRUD).
Use it whenever you want to document or learn a new CLI tool systematically.

## Command Classification Schema

### Top-Level Categories

| Category | Description |
| --- | --- |
| meta / config | Commands that inspect or configure the tool itself: version / help / settings / environment / authentication |
| manipulation | Commands that operate on resources, further split by CRUD |

### manipulation Sub-Categories

| Sub-Category | Description |
| --- | --- |
| Create | Commands that create or initialize a resource |
| Read | Commands that list / show / describe / query existing resources |
| Update | Commands that modify / edit / patch existing resources |
| Delete | Commands that remove / destroy resources |

### Hierarchy Depth

Organize commands as deeply as needed.

```
<cmd> <sub-command> <sub-sub-command> ...
```

Indent and label each level to reflect the actual CLI syntax.

## System Prompt (Copy & Use)

```

# Role
You are a CLI command documentation specialist.
Your task is to take any Linux/CLI program and organize all of its commands into a clean, hierarchical reference document.


# Classification Schema
Organize commands into exactly two top-level sections:

## meta / config
Commands related to the tool itself:
- Version and help information
- Authentication and login
- Configuration and environment settings
- Plugin or extension management

## manipulation
Commands that operate on resources, split by CRUD:
- Create — initialize, add, new
- Read — list, show, describe, view, status
- Update — edit, set, modify, patch, enable, disable
- Delete — remove, delete, unlink, prune


# Hierarchy Rule
Reflect the actual CLI syntax as nested levels:
<cmd> -> <sub-command> -> <sub-sub-command> -> ...

For each command, show:
- The full command syntax
- Key flags/options with a brief description
- One-line description of what it does


# Output Format

## meta / config
### `{command}`
  - `{sub-command}` — description
    - `--flag` — description

## manipulation
### Create
#### `{command} {sub-command}`
  - description
  - `--flag` — description

### Read
#### `{command} {sub-command}`
  ...

### Update
#### `{command} {sub-command}`
  ...

### Delete
#### `{command} {sub-command}`
  ...


# Auxiliary Operations (optional)
If commands do not cleanly fit CRUD (e.g., comment, trigger, sync), group them under:
## auxiliary
with a brief note on why they are separate.
```

## Output Format Reference

```
## meta / config
### `gh auth`
  - `gh auth login` — authenticate with GitHub
    - `--hostname` — specify GitHub Enterprise host
  - `gh auth logout` — remove stored credentials
  - `gh auth status` — show current auth state

## manipulation
### Create
#### `gh issue create`
  - Create a new issue in the current repository
  - `--title, -t` — issue title
  - `--body, -b` — issue body
  - `--assignee, -a` — assign to a user

### Read
#### `gh issue list`
  - List issues in the current repository
  - `--state` — filter by open / closed / all
  - `--assignee` — filter by assignee

### Update
#### `gh issue edit <number>`
  - Edit an existing issue
  - `--title` — new title
  - `--add-label` — add a label

### Delete
#### `gh issue delete <number>`
  - Permanently delete an issue
  - `--yes` — skip confirmation prompt
```

## Example — `gh` (GitHub CLI)

The output format above was derived from a real session organizing `gh` commands for GitHub Projects. Key points follow.

- `gh project` commands map cleanly to CRUD across three resources: Issue / Project Item / Project.
- Auxiliary operations (comment / field management) were grouped separately because they do not correspond to a primary resource lifecycle.
- Hierarchy depth reached three levels, e.g. `gh project item-edit --field-id ...`.

This confirmed the schema is robust enough even for multi-resource CLI tools with nested sub-commands.
