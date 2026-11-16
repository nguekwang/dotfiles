#!/usr/bin/env python3
"""Deterministic keybinding extractor for this repository's dotfiles.

Parses user/hypr/hyprland.lua, user/hypr/foot.ini, user/browsers/qutebrowser.py,
and user/nvim/init.lua with regex/balanced-paren rules (no LLM calls), and
renders silver-lake/dev/keybindings.md and an HTML reference page from the same
extracted data. See reference.md in this skill directory for the exact
pattern each source relies on and its known limitations.

Usage:
    python3 extract-keybindings.py <repo_root> <md_out_path> <html_out_path>
"""
import datetime
import html
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def strip_full_line_comments(text: str, marker: str = "--") -> str:
    """Blank out lines that are entirely a comment, so a commented-out call
    is never mistaken for a live one. Leaves inline/trailing comments and
    multi-line bracket strings alone -- those don't start a line with the
    marker."""
    out = []
    for line in text.splitlines():
        out.append("" if line.strip().startswith(marker) else line)
    return "\n".join(out)


def iter_balanced_calls(text: str, call_prefix: str):
    """Yield the inside-the-parens text of every `call_prefix(...)` call,
    matched by paren depth rather than a single regex, so a call that spans
    multiple lines or nests other calls is captured whole."""
    for m in re.finditer(re.escape(call_prefix) + r"\s*\(", text):
        start = m.end() - 1  # index of the opening '('
        depth = 0
        i = start
        while i < len(text):
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
                if depth == 0:
                    yield text[start + 1 : i]
                    break
            i += 1


# ---------------------------------------------------------------------------
# Hyprland (user/hypr/hyprland.lua)
# ---------------------------------------------------------------------------

HYPR_KEY_DISPLAY = {
    "comma": ",",
    "semicolon": ";",
    "Return": "Enter",
}
HYPR_MOUSE_DISPLAY = {
    "mouse:272": "マウス左ボタン",
    "mouse:273": "マウス右ボタン",
}


def parse_hyprland(path: Path):
    text = strip_full_line_comments(path.read_text())

    main_match = re.search(r'local\s+main\s*=\s*"([^"]+)"', text)
    main_key = main_match.group(1) if main_match else "SUPER"

    rows = []
    for call in iter_balanced_calls(text, "hl.bind"):
        combo_match = re.search(r'main\s*\.\.\s*"([^"]*)"', call)
        desc_match = re.search(r'description\s*=\s*"([^"]*)"', call)
        if not combo_match or not desc_match:
            continue  # not a modifier-chord bind this parser understands
        tokens = [t.strip() for t in combo_match.group(1).split("+") if t.strip()]
        *modifiers, key = tokens
        key_display = HYPR_MOUSE_DISPLAY.get(key, HYPR_KEY_DISPLAY.get(key, key))
        combo = " + ".join([main_key, *modifiers, key_display])
        rows.append({"keys": combo, "action": desc_match.group(1)})
    return rows


# ---------------------------------------------------------------------------
# foot (user/hypr/foot.ini)
# ---------------------------------------------------------------------------

FOOT_ACTION_DISPLAY = {
    "scrollback-up-line": "スクロールバックを1行上へ",
    "scrollback-down-line": "スクロールバックを1行下へ",
    "scrollback-up-page": "スクロールバックを1ページ上へ",
    "scrollback-down-page": "スクロールバックを1ページ下へ",
}


def parse_foot(path: Path):
    text = path.read_text()
    section_match = re.search(r"^\[key-bindings\]\s*$(.*?)(^\[|\Z)", text, re.M | re.S)
    if not section_match:
        return []
    rows = []
    for line in section_match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        action, combo = line.split("=", 1)
        action = action.strip()
        rows.append({
            "keys": combo.strip(),
            "action": FOOT_ACTION_DISPLAY.get(action, action),
        })
    return rows


# ---------------------------------------------------------------------------
# qutebrowser (user/browsers/qutebrowser.py)
# ---------------------------------------------------------------------------

def parse_qutebrowser(path: Path):
    text = path.read_text()

    # Resolve `for <var> in [<literal strings>]:` blocks whose indented body
    # calls config.bind(..., mode=<var>) -- the only dynamic-mode shape this
    # file uses. Maps call-start-offset -> resolved mode label.
    loop_mode_at = {}
    for loop_match in re.finditer(r"for\s+(\w+)\s+in\s+\[([^\]]+)\]\s*:\s*\n", text):
        var = loop_match.group(1)
        modes = re.findall(r"""['"]([^'"]+)['"]""", loop_match.group(2))
        if not modes:
            continue
        block_start = loop_match.end()
        lines = text[block_start:].splitlines(keepends=True)
        block_lines = []
        for line in lines:
            if line.strip() == "" or line.startswith((" ", "\t")):
                block_lines.append(line)
                continue
            break
        block_text = "".join(block_lines)
        block_offset = block_start
        for bind_match in re.finditer(
            r"config\.bind\(\s*['\"][^'\"]+['\"]\s*,\s*['\"][^'\"]+['\"]\s*,\s*mode\s*=\s*"
            + re.escape(var) + r"\s*\)",
            block_text,
        ):
            loop_mode_at[block_offset + bind_match.start()] = " / ".join(modes)

    rows = []
    bind_pattern = re.compile(
        r"""config\.bind\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]"""
        r"""(?:\s*,\s*mode\s*=\s*(?:['"]([^'"]+)['"]|(\w+)))?\s*\)"""
    )
    for m in bind_pattern.finditer(text):
        quoted_mode, bare_mode = m.group(3), m.group(4)
        if bare_mode:
            # mode=<loop var> -- only resolvable via the loop-block scan above.
            mode = loop_mode_at.get(m.start(), bare_mode)
        else:
            mode = quoted_mode or "normal"
        rows.append({"keys": m.group(1), "action": m.group(2), "mode": mode})

    # The file's own `map(key, command)` helper (defined a few lines above
    # its first use) is a pure unbind+bind passthrough with no mode kwarg --
    # confirmed by reading its body, not assumed. If that body ever stops
    # being a plain passthrough, this rule must be revisited (see reference.md).
    map_def = re.search(r"def\s+map\(key,\s*command\):\s*\n(.*?)\n\n", text, re.S)
    if map_def and "config.unbind(key)" in map_def.group(1) and "config.bind(key, command)" in map_def.group(1):
        for m in re.finditer(r"""^\s*map\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*\)""", text, re.M):
            rows.append({"keys": m.group(1), "action": m.group(2), "mode": "normal"})

    return rows


# ---------------------------------------------------------------------------
# Neovim (user/nvim/init.lua)
# ---------------------------------------------------------------------------

NVIM_MODE_DISPLAY = {
    "n": "ノーマル",
    "i": "インサート",
    "v": "ビジュアル",
    "x": "ビジュアル(矩形)",
    "t": "ターミナル",
    "c": "コマンドライン",
}


def parse_nvim(path: Path):
    text = strip_full_line_comments(path.read_text())
    rows = []
    for call in iter_balanced_calls(text, "vim.keymap.set"):
        head_match = re.match(r"""\s*['"](\w+)['"]\s*,\s*['"]([^'"]+)['"]\s*,\s*(.*)""", call, re.S)
        if not head_match:
            continue
        mode, key, rest = head_match.groups()

        desc_match = re.search(r"""desc\s*=\s*['"]([^'"]+)['"]""", rest)
        if desc_match:
            action = desc_match.group(1)
        else:
            # rest is either a quoted/bracket-string rhs followed by `, { ... }`,
            # or an inline function body -- fall back to a literal rhs excerpt.
            rhs_match = re.match(r"""\s*\[\[(.*?)\]\]|\s*['"]([^'"]+)['"]""", rest, re.S)
            if rhs_match:
                action = "`" + (rhs_match.group(1) or rhs_match.group(2)) + "`"
            else:
                action = "(無名関数、descなし)"

        rows.append({
            "keys": key,
            "action": action,
            "mode": NVIM_MODE_DISPLAY.get(mode, mode),
        })
    return rows


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

SECTIONS = [
    {
        "id": "hyprland",
        "title": "Hyprland (ウィンドウマネージャ)",
        "path": "user/hypr/hyprland.lua",
        "parser": parse_hyprland,
        "columns": ["keys", "action"],
        "headers": ["キー", "動作"],
    },
    {
        "id": "foot",
        "title": "foot (ターミナル)",
        "path": "user/hypr/foot.ini",
        "parser": parse_foot,
        "columns": ["keys", "action"],
        "headers": ["キー", "動作"],
    },
    {
        "id": "qutebrowser",
        "title": "qutebrowser (ブラウザ、Meta = Superキー)",
        "path": "user/browsers/qutebrowser.py",
        "parser": parse_qutebrowser,
        "columns": ["keys", "action", "mode"],
        "headers": ["キー", "コマンド", "モード"],
    },
    {
        "id": "nvim",
        "title": "Neovim (エディタ、<D-x> = Superキー)",
        "path": "user/nvim/init.lua",
        "parser": parse_nvim,
        "columns": ["mode", "keys", "action"],
        "headers": ["モード", "キー", "動作"],
    },
]


def build_sections(repo_root: Path):
    sections = []
    for spec in SECTIONS:
        file_path = repo_root / spec["path"]
        rows = spec["parser"](file_path) if file_path.exists() else []
        sections.append({**spec, "rows": rows})
    return sections


def render_markdown(sections, generated_at: str) -> str:
    lines = [
        "# キーバインド一覧",
        "",
        f"生成日時: {generated_at}",
        "",
        "`.claude/skills/document-keybindings/scripts/extract-keybindings.py` が各設定ファイルから"
        "決定的に抽出した結果。設定ファイルを変更したら、このスクリプトを再実行して更新する"
        "(手動で編集しない)。",
        "",
    ]
    for sec in sections:
        lines.append(f"## {sec['title']}")
        lines.append("")
        lines.append(f"出典: `{sec['path']}`")
        lines.append("")
        if not sec["rows"]:
            lines.append("(抽出対象のバインドなし)")
            lines.append("")
            continue
        lines.append("| " + " | ".join(sec["headers"]) + " |")
        lines.append("| " + " | ".join("---" for _ in sec["headers"]) + " |")
        for row in sec["rows"]:
            cells = [str(row.get(col, "")) for col in sec["columns"]]
            lines.append("| " + " | ".join(cells) + " |")
        lines.append("")
    return "\n".join(lines)


HTML_TEMPLATE = """<title>キーバインド便覧</title>
<style>
:root {{
  --bg: #f4f4f2;
  --surface: #ffffff;
  --border: #d8d8d4;
  --text: #1a1a1a;
  --text-dim: #6b6b6b;
  --accent: #2a4a9b;
  --mono: 'JetBrains Mono', ui-monospace, Menlo, Consolas, monospace;
  --sans: 'IBM Plex Sans', 'Noto Sans JP', system-ui, sans-serif;
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --bg: #0d0d0d;
    --surface: #161616;
    --border: #2a2a2a;
    --text: #c7c7c7;
    --text-dim: #888888;
    --accent: #6f93e8;
  }}
}}
:root[data-theme="dark"] {{
  --bg: #0d0d0d;
  --surface: #161616;
  --border: #2a2a2a;
  --text: #c7c7c7;
  --text-dim: #888888;
  --accent: #6f93e8;
}}
* {{ box-sizing: border-box; }}
body {{
  background: var(--bg);
  color: var(--text);
  font-family: var(--sans);
  margin: 0;
  display: flex;
  min-height: 100vh;
}}
nav {{
  position: sticky;
  top: 0;
  align-self: flex-start;
  width: 220px;
  flex-shrink: 0;
  padding: 2rem 1rem;
  border-right: 1px solid var(--border);
  height: 100vh;
  overflow-y: auto;
}}
nav h2 {{
  font-family: var(--mono);
  font-size: 0.75rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-dim);
  margin: 0 0 0.75rem;
}}
nav ul {{ list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 0.5rem; }}
nav a {{ color: var(--text); text-decoration: none; font-size: 0.9rem; }}
nav a:hover, nav a:focus-visible {{ color: var(--accent); }}
main {{
  flex: 1;
  padding: 2.5rem 3rem 4rem;
  max-width: 900px;
}}
h1 {{
  font-family: var(--mono);
  font-size: 1.9rem;
  margin: 0 0 0.25rem;
  text-wrap: balance;
}}
.meta {{ color: var(--text-dim); font-size: 0.85rem; margin: 0 0 2.5rem; }}
section {{ margin-bottom: 3rem; scroll-margin-top: 1rem; }}
section h2 {{
  font-size: 1.15rem;
  margin: 0 0 0.25rem;
  border-bottom: 1px solid var(--border);
  padding-bottom: 0.5rem;
}}
.source-path {{
  font-family: var(--mono);
  font-size: 0.78rem;
  color: var(--text-dim);
  margin: 0 0 1rem;
}}
.table-wrap {{ overflow-x: auto; border: 1px solid var(--border); border-radius: 6px; }}
table {{ width: 100%; border-collapse: collapse; background: var(--surface); }}
th, td {{ text-align: left; padding: 0.55rem 0.9rem; border-bottom: 1px solid var(--border); font-size: 0.9rem; }}
th {{ color: var(--text-dim); font-weight: 600; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.04em; }}
tr:last-child td {{ border-bottom: none; }}
kbd {{
  font-family: var(--mono);
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 0.1rem 0.45rem;
  font-size: 0.85rem;
  white-space: nowrap;
}}
.empty {{ color: var(--text-dim); font-style: italic; padding: 0.9rem; }}
code {{ font-family: var(--mono); background: var(--bg); padding: 0.05rem 0.35rem; border-radius: 3px; }}
@media (max-width: 720px) {{
  body {{ flex-direction: column; }}
  nav {{ position: static; width: auto; height: auto; border-right: none; border-bottom: 1px solid var(--border); }}
  main {{ padding: 2rem 1.25rem 3rem; }}
}}
</style>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
<nav>
  <h2>ソース</h2>
  <ul>
{nav_items}
  </ul>
</nav>
<main>
  <h1>キーバインド便覧</h1>
  <p class="meta">生成日時: {generated_at} / extract-keybindings.py で再生成</p>
{sections_html}
</main>
"""


def render_html(sections, generated_at: str) -> str:
    nav_items = "\n".join(
        f'    <li><a href="#{sec["id"]}">{html.escape(sec["title"])}</a></li>' for sec in sections
    )
    sections_html = []
    for sec in sections:
        rows_html = []
        if sec["rows"]:
            header_html = "".join(f"<th>{html.escape(h)}</th>" for h in sec["headers"])
            body_rows = []
            for row in sec["rows"]:
                cells = []
                for col in sec["columns"]:
                    value = str(row.get(col, ""))
                    if col == "keys":
                        cells.append(f"<td><kbd>{html.escape(value)}</kbd></td>")
                    else:
                        cells.append(f"<td>{html.escape(value)}</td>")
                body_rows.append("<tr>" + "".join(cells) + "</tr>")
            table_html = (
                f'<div class="table-wrap"><table><thead><tr>{header_html}</tr></thead>'
                f'<tbody>{"".join(body_rows)}</tbody></table></div>'
            )
        else:
            table_html = '<div class="empty">抽出対象のバインドなし</div>'
        sections_html.append(
            f'  <section id="{sec["id"]}">\n'
            f'    <h2>{html.escape(sec["title"])}</h2>\n'
            f'    <p class="source-path"><code>{html.escape(sec["path"])}</code></p>\n'
            f"    {table_html}\n"
            f"  </section>"
        )
    return HTML_TEMPLATE.format(
        nav_items=nav_items,
        generated_at=html.escape(generated_at),
        sections_html="\n".join(sections_html),
    )


def main():
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} <repo_root> <md_out_path> <html_out_path>", file=sys.stderr)
        sys.exit(1)
    repo_root = Path(sys.argv[1]).resolve()
    md_out = Path(sys.argv[2])
    html_out = Path(sys.argv[3])

    generated_at = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    sections = build_sections(repo_root)

    md_out.parent.mkdir(parents=True, exist_ok=True)
    md_out.write_text(render_markdown(sections, generated_at))

    html_out.parent.mkdir(parents=True, exist_ok=True)
    html_out.write_text(render_html(sections, generated_at))

    total = sum(len(sec["rows"]) for sec in sections)
    print(f"extracted {total} bindings across {len(sections)} sources")
    for sec in sections:
        print(f"  {sec['id']}: {len(sec['rows'])}")


if __name__ == "__main__":
    main()
