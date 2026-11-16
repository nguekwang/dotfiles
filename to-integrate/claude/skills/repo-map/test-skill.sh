#!/usr/bin/env bash
# test-skill.sh: 生成されたスキルの構造を検証する。
# MUSE-Autoskill の TEST 段階で使う。機能面の検証は別途タスクを実行して行うこと。
# 使い方: bash test-skill.sh <skill-name>
set -u

name="${1:-}"
if [ -z "$name" ]; then
  echo "FAIL: スキル名を引数で渡してください (例: test-skill.sh pdf-extract)"
  exit 2
fi

dir=".claude/skills/${name}"
md="${dir}/SKILL.md"
fail=0

note() { printf -- "%-6s %s\n" "$1" "$2"; }

# 1. ディレクトリと SKILL.md の存在
if [ ! -d "$dir" ]; then
  note "FAIL" "ディレクトリが無い: ${dir}"; exit 1
fi
if [ ! -f "$md" ]; then
  note "FAIL" "SKILL.md が無い: ${md}"; exit 1
fi
note "OK" "SKILL.md 存在: ${md}"

# 2. 命名規則 (kebab-case)
if printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  note "OK" "命名は kebab-case"
else
  note "FAIL" "命名が kebab-case でない: ${name}"; fail=1
fi

# 3. frontmatter の存在 (先頭行が ---)
if [ "$(head -n 1 "$md")" = "---" ]; then
  note "OK" "frontmatter あり"
else
  note "FAIL" "先頭に frontmatter (---) が無い"; fail=1
fi

# 4. description フィールドの存在と長さ
desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,"");print;exit}' "$md")
if [ -z "$desc" ]; then
  note "FAIL" "description が無い (自動発火しない)"; fail=1
elif [ "${#desc}" -lt 15 ]; then
  note "WARN" "description が短すぎる (発火しづらい): ${desc}"
else
  note "OK" "description あり (${#desc} 文字)"
fi

# 5. 絵文字・装飾記号の簡易チェック (prose-style スキル)
if LC_ALL=C grep -nP '[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}]' "$md" >/dev/null 2>&1; then
  note "WARN" "絵文字らしき文字を検出 (prose-style スキルは絵文字禁止)"
fi

# 6. 本文 (frontmatter 後) が空でない
body_lines=$(awk 'f&&NF{c++} /^---$/{n++; if(n==2)f=1} END{print c+0}' "$md")
if [ "${body_lines:-0}" -ge 1 ]; then
  note "OK" "本文あり (${body_lines} 行)"
else
  note "FAIL" "本文が空 (手順が書かれていない)"; fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  note "PASS" "構造検査を通過。次に機能検証 (代表タスクの実行) を行うこと。"
  exit 0
else
  note "FAIL" "構造検査に失敗。SKILL.md を修正して再実行すること。"
  exit 1
fi
