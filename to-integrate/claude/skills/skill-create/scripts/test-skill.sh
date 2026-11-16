#!/usr/bin/env bash

# test-skill.sh: 生成されたスキルの構造を検証する。

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
if [ "$name" != "$(printf '%s' "$name" | LC_ALL=C sed -E 's/[^a-z0-9]/-/g; s/-+/-/g; s/^-|-$//g')" ]; then
  note "FAIL" "命名が kebab-case でない: ${name}"; fail=1
else
  note "OK" "命名は kebab-case"
fi

# 3. frontmatter (name, description) の有無
if ! grep -q '^name:' "$md"; then
  note "WARN" "frontmatter に name: が無い"
fi
if ! grep -q '^description:' "$md"; then
  note "FAIL" "frontmatter に description: が無い (発火条件を書くこと)"; fail=1
else
  note "OK" "description あり"
fi

# 4. 絵文字・装飾記号の簡易チェック (リポジトリ規約)
if LC_ALL=C grep -nP '[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}]' "$md" >/dev/null 2>&1; then
  note "WARN" "絵文字らしき文字を検出 (規約は絵文字禁止)"
fi

# 5. 本文 (frontmatter 後) が空でない
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