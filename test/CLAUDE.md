# test

Checks that `setup.sh` and the files it links still agree, without touching the
machine. POSIX `sh`, reads the checkout only.

```sh
./test/all
```

| File | Role |
| --- | --- |
| `all` | runs every `*-test.sh`, keeps going past a failure, exits non-zero if any failed |
| `base-test.sh` | sourced by each test: `path_root`, `path_setup`, `pass`, `fail` |
| `deployment-test.sh` | `setup.sh` parses; `link` and `probe_path` exist; every step in `list_step_label` has a `setup_` function and a row in the `CLAUDE.md` steps table; the other `list_step_*` lists name only known steps; every `link` source exists; every file under `home/` and `etc/` is linked |

A test prints `ok - <what>`, or `not ok - <what>` on stderr and exits at the
first failure. A new area is `test/<area>-test.sh`, starting with
`. "$(dirname "$0")/base-test.sh"`; `all` picks it up. Assert an invariant, not
a snapshot.
