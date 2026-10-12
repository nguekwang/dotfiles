# complete-works

Machine setup for Arch Linux. One POSIX `sh` script, no arguments, safe to run
as many times as you like.

```sh
sh setup.sh
```

Everything else — the philosophy behind the script, what a run prints, what it
writes, how rollback works, and the list of steps — is in
**[CLAUDE.md](CLAUDE.md)**.

Deployment checks, without running setup or changing the machine:

```sh
sh test/all
```

The tests and dotfile-wiring hook were migrated from
`nguekwang/pjt-transfer-previous-accounts`. They use this repository's `home/`,
`etc/` and `link user` / `link sudo` interface. There is no migration runner in
this setup, so the previous migration test is retired. See `test/CLAUDE.md`.
