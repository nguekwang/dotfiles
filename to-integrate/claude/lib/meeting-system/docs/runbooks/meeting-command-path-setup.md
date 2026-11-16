# Meeting Command PATH Setup

This runbook explains how to make the meeting start commands available directly from your shell.

## Commands

The repository includes these command entry points:

- `open-meeting`
- `start-claude-meeting`

They are provided via the wrappers in `bin/`, which forward to the scripts under `scripts/utils/`.

## Temporary Setup

Add the repository `bin/` directory to `PATH` for the current shell session:

```bash
export PATH="$HOME/complete-works/.claude/lib/meeting-system/bin:$PATH"
```

After that, you can run:

```bash
open-meeting
start-claude-meeting [<meeting-name> <purpose> [constraints] [participants]]
```

`open-meeting` launches the new meeting wizard:

1. `Which model?`
2. `Meeting name?`
3. `Meeting purpose?`
4. `Meeting constraints?`
5. `Who should participate?`

The model selector uses arrow keys. The participant selector reads agent ids from `agents/`, defaults to `all`, and supports multi-select with Space.

If you only want to inspect the generated kickoff prompt, add `--dry-run`.

## Persistent Setup For zsh

Append the same `PATH` export to `~/.zshrc`:

```bash
echo 'export PATH="$HOME/complete-works/.claude/lib/meeting-system/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Verification

Confirm that the command resolves from `PATH`:

```bash
command -v open-meeting
command -v start-claude-meeting
```

You can also validate the prompt generation without starting an interactive session:

```bash
open-meeting --dry-run naming-policy "命名規則を決める" "今週中に合意" all
```

## Notes

- The path above assumes this repository is cloned at `~/complete-works`. If it lives
  elsewhere, adjust the export accordingly.
- The wrappers assume the repository layout remains unchanged.
