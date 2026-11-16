#!/usr/bin/env bash
# open-in-chrome.sh <path-or-file-URI>
#
# Opens a local file in Chrome. Markdown is rendered to HTML first, because
# Chrome shows a .md file as raw plain text otherwise. The URI passed to
# Chrome is always built with Python's pathlib.Path.as_uri(), which percent-
# encodes spaces and non-ASCII characters correctly; do not hand-build it.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input="${1:?usage: open-in-chrome.sh <path-or-file-URI>}"

# Accept a file:// URI or a plain path; normalize to a plain path either way.
case "$input" in
  file://*)
    path="$(python3 -c '
import sys, urllib.parse, urllib.request
print(urllib.request.url2pathname(urllib.parse.urlparse(sys.argv[1]).path))
' "$input")"
    ;;
  *)
    path="$input"
    ;;
esac

path="$(realpath -e "$path")"

case "$path" in
  *.md | *.markdown)
    cache_root="$HOME/.cache/open-files-in-chrome"
    cache_path="${cache_root}${path%.*}.html"
    mkdir -p "$(dirname "$cache_path")"
    pandoc_args=(--standalone --metadata "title=$(basename "$path")")
    has_mermaid=0
    if grep -qE '^```+[[:space:]]*mermaid[[:space:]]*$' "$path"; then
      has_mermaid=1
      pandoc_args+=(--include-after-body="$script_dir/mermaid-embed.html")
    fi
    pandoc "${pandoc_args[@]}" -o "$cache_path" "$path"
    if [ "$has_mermaid" = 1 ]; then
      # Pandoc emits a ```mermaid fence as <pre class="mermaid"><code>...
      # </code></pre>. mermaid.js's `.mermaid` auto-render selector expects
      # the diagram source as the element's own content with no nested
      # <code> child - left in place, it reads the literal "<code>..."
      # markup as part of the diagram text and fails with "Syntax error in
      # text" (confirmed live: identical source rendered correctly once the
      # <code> wrapper was stripped, in Chrome via claude-in-chrome).
      perl -0777 -pi -e 's{<pre class="mermaid"><code>(.*?)</code></pre>}{<pre class="mermaid">$1</pre>}gs' "$cache_path"
    fi
    target="$cache_path"
    ;;
  *)
    target="$path"
    ;;
esac

uri="$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$target")"

# Chrome is single-instance: launching it again with a URL opens a new tab in
# the already-running window instead of a new window, so an open window is
# reused automatically. No browser-automation tool is involved — the
# claude-in-chrome extension's navigate refuses file:// URIs outright.
nohup google-chrome-stable "$uri" >/dev/null 2>&1 &
disown
