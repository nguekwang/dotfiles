# drive-qutebrowser

Drive a running qutebrowser instance from the CLI -- the equivalent of
claude-in-chrome's browser automation, but for qutebrowser. Exists because
qutebrowser (QtWebEngine-based) can't run Chrome extensions at all, so the
extension-based claude-in-chrome mechanism has nothing to attach to there.

## How it works

qutebrowser is single-instance: running `qutebrowser <args>` while an
instance is already open sends those args to it over IPC instead of starting
a second process ("Opening in existing instance"). That covers *commands*
(open a URL, go back, scroll, ...) for free.

*Reading* a page back out is the part qutebrowser doesn't expose a clean
channel for -- `:jseval` runs arbitrary JS in the page, but its result only
ever gets printed as an `INFO:` line in qutebrowser's own stdout, with no
return value handed back over IPC. So `drive-qutebrowser` launches qutebrowser itself
with stdout redirected to `$XDG_CACHE_HOME/drive-qutebrowser/qutebrowser.log`, and the
read subcommands (`js`/`text`/`url`/`title`) send the `:jseval` command, then
tail that log file for the next new line.

**This only works for an instance `drive-qutebrowser` itself launched** (via `ensure`,
or any subcommand -- they all call `ensure` first). If qutebrowser is already
running from somewhere else (a keybind, a terminal, manually), `open`/`cmd`
still work fine since they don't need the log, but `js`/`text`/`url`/`title`
have nothing to tail and will print a warning instead of a result.

## Usage

```sh
drive-qutebrowser ensure                        # launch qutebrowser if not already running
drive-qutebrowser open https://example.com      # open a URL in a new tab
drive-qutebrowser cmd ":back"                   # send any raw qutebrowser command
drive-qutebrowser js "document.title"           # eval JS, print the result
drive-qutebrowser text                          # current page's visible text
drive-qutebrowser url                           # current page's URL
drive-qutebrowser title                         # current page's title
```

## Known limits

- **No structured return values.** Results are whatever `:jseval` happens to
  log as a string -- fine for text/strings, lossy for objects/arrays (JS's
  default stringification, not JSON).
- **Fire-and-forget commands race the log tail.** `js`/`text`/etc. poll the
  log for up to 3s after sending the command; a page that's still loading or
  a JS call that throws may just time out with no result.
- **Don't point this at anything sensitive unattended.** `open`/`cmd` will
  happily navigate whatever tab is focused -- if you have something like a
  logged-in banking session open, a stray `drive-qutebrowser open`/`cmd` call can
  switch focus to a new tab (it won't close the existing one, but it does
  change what's in front). Treat automated calls the same way you'd treat
  typing in that terminal by hand: don't run them unattended against a tab
  you care about staying put.
- **No credential handling, ever.** This tool has no concept of filling in
  a password field. Anything that needs a secret belongs to the person at
  the keyboard, typed into the browser directly -- see the Rakuten Bank
  login this was built alongside, where `drive-qutebrowser open` got the page open
  and the login itself stayed manual.
