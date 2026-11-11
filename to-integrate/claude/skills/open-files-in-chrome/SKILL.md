---
name: open-files-in-chrome
description: >-
  Open a local file (a repository file, a path the user pastes or @-mentions,
  or a file:// URI) in Chrome. Fires on "chromeで開いて" / "open in chrome" /
  "open this file in the browser" for anything that is not already an
  http(s) URL. Converts a plain path to the correct file:// URI, reuses an
  already-open Chrome window instead of forcing a new one, and renders
  Markdown to HTML first instead of showing it as raw text.
---

# open-files-in-chrome

Opens a local file in Chrome. Handles two problems a plain `file://` open
does not: Chrome shows a `.md` file as raw source instead of a rendered page,
and the `claude-in-chrome` browser-automation extension's `navigate` tool
refuses `file://` URIs entirely (`Can't interact with browser-internal or
unparseable URLs`), so this must not go through that tool.

## 手順

1. Resolve what the user gave you to an absolute local path: a bare path, a
   `@`-mentioned path, or a `file://` URI (strip the scheme and URL-decode
   it). If it is instead an `http(s)://` URL, this skill does not apply — use
   the `claude-in-chrome` navigate tool as normal.
2. Run the bundled script, passing the resolved path or the original
   `file://` URI:
   ```bash
   bash .claude/skills/open-files-in-chrome/scripts/open-in-chrome.sh <path-or-uri>
   ```
   The script:
   - Builds the `file://` URI from the path with Python's
     `pathlib.Path.as_uri()`, which percent-encodes spaces and non-ASCII
     characters (including Japanese file names) correctly. Never hand-build
     this URI with string concatenation.
   - If the file is `.md`/`.markdown`, renders it to HTML with `pandoc
     --standalone` into `~/.cache/open-files-in-chrome/<mirrored-path>.html`
     first, and opens that instead of the raw source.
   - If that Markdown source contains a ` ```mermaid ` fence, also passes
     `--include-after-body=scripts/mermaid-embed.html` to pandoc. Pandoc's
     default HTML writer already emits a fenced ```mermaid block as
     `<pre class="mermaid"><code>...</code></pre>`, which is exactly what
     mermaid.js's own `.mermaid` auto-render selector expects — no HTML
     transformation is needed, only the library. The embed snippet loads
     mermaid.js as an ES module from jsDelivr and calls
     `mermaid.initialize({ startOnLoad: true })`. Files with no mermaid fence
     skip this (no needless CDN fetch), so `figure-rendering`'s existing
     ```mermaid output renders as an actual diagram once opened, instead of
     as a plain code block.
   - Launches `google-chrome-stable <uri>` in the background. Chrome is
     single-instance, so if a Chrome window is already open this adds a tab
     to it rather than opening a new window; if none is open, it starts one.
     This is the reuse mechanism — there is no separate "is a window open"
     check to run first.
3. Report the path actually opened (the generated HTML path for Markdown,
   the original path otherwise), not the source path, when they differ.

## 補足

- Do not attempt this through the `claude-in-chrome` MCP tools
  (`navigate`, `tabs_create_mcp`, ...). Verified in session: `navigate` to a
  `file://` URL errors with "Can't interact with browser-internal or
  unparseable URLs" even on a fresh tab. Those tools are for web pages only;
  this skill's script is the only supported path for local files.
- The Markdown cache mirrors the source's absolute path under
  `~/.cache/open-files-in-chrome/`, so it never writes into the repository
  and regenerates (overwrites) on every open — always current, no staleness
  to track.
- Extend the script's `case` statement, not this file, if another format
  ever needs its own rendering step before opening.
- Open only as many tabs as the task strictly needs — do not open a new one
  while another opened for the same request is still in use.
- Once the user is done with a tab this skill opened, ask before closing it
  ("このタブ消していいですか？") rather than closing it unprompted or
  leaving it open indefinitely.
