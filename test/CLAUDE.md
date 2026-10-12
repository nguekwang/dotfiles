# test

Checks that the repository's deployment path is intact, runnable on any machine with `sh`, and without touching the machine. Modeled on omarchy's `test/` (a runner that keeps going past a failing suite, TAP-style `ok` / `not ok` lines, exit on the first failed assertion within a file), reduced to what a dotfiles repository needs.

## Layout

| File | Role |
| --- | --- |
| `all` | Runner: executes every `*-test.sh` here, reports the failed ones at the end, exits non-zero if any failed |
| `base-test.sh` | Sourced library: `ROOT`, `pass`, `fail`, `skip` |
| `deployment-test.sh` | `setup.sh` parses; every `link_*` helper it calls is defined; every link source exists; every dotfile under `user/` and `etc/` is wired into `setup.sh` or listed in `unwired-files.txt` |
| `migrations-test.sh` | Every migration follows the contract in `migrations/CLAUDE.md` |
| `unwired-files.txt` | Files under `user/` and `etc/` that `setup.sh` deliberately does not deploy, one per line with the reason on the same line after a tab |

## Running

```sh
./test/all
```

Every test is POSIX sh and reads the checkout only; no test writes outside `mktemp -d`.

## Adding a test

Create `test/<area>-test.sh`, start it with `. "$(dirname "$0")/base-test.sh"`, and it is picked up by `all`. Assert an invariant, not a snapshot, so unrelated edits do not fail it.
