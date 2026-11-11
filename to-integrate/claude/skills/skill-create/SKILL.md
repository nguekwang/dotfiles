---
name: skill-create
description: Self-evolving skill generation loop (MUSE-Autoskill). When a new task arrives, first check whether an existing skill can solve it; if not, automatically create a new rule skill, iterate until its structure test passes, and memorize it in the registry. Fires on explicit "create a skill" / "skill を作成" / "skill-create" requests and on repeatable tasks not covered by existing skills.
---

# skill-create: 自己進化型スキル生成ループ

論文 MUSE-Autoskill (Self-Evolving Agents via Skill Creation, Memory) の中核ループを
スキル機構の上で再現するメタスキルである。追加の API 課金は発生しない。

中核の主張は次の通り。新しい問題が来たら、まず既存スキルで解けるか確認し、
解けなければ新スキルを自動生成してテストまで通す。生成したスキルは記憶し再利用する。

## 実行ループ (4 段階)

タスク `$ARGUMENTS` に対して、以下を順に実行する。

### 1. REUSE — 既存スキルで解けるか確認

現在登録されている全スキルの一覧と説明は以下に展開される。

```!
echo "## 既存スキル一覧"
for f in .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir=$(basename "$(dirname "$f")")
  desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,"");print;exit}' "$f")
  printf -- "- %s : %s\n" "$dir" "$desc"
done
echo
echo "## 記憶レジストリ"
[ -f .claude/skills/skill-create/registry.md ] && tail -n 40 .claude/skills/skill-create/registry.md || echo "(まだ記憶なし)"
```

判定基準:

- 上記の一覧に、タスクを十分カバーするスキルが存在するか。
- 存在する場合: そのスキルを使う旨を伝え、このループは終了する。新規生成はしない。
- 存在しない、または部分的にしか解けない場合: 段階 2 へ進む。

判断は保守的に行う。既存スキルで 8 割方解けるなら、新規作成ではなく既存スキルの
改善 (段階 2 の variant) を選ぶ。重複スキルを増やさないことを最優先とする。

### 2. CREATE — 新スキルを自動生成

新スキルの設計を行い、ファイルを作成する。

1. 名前を kebab-case で決める (例: `pdf-extract`, `commit-message`)。既存ディレクトリと衝突しないこと。
2. `.claude/skills/<name>/SKILL.md` を作成する。テンプレートは [reference.md](reference.md) のスキル雛形に従う。
   - frontmatter の `description` は「何をするか + いつ使うか」を具体的に書く。自動発火はこの記述で決まる。
   - 本文には、再現可能な手順を箇条書きで書く。曖昧語を避け、検証可能なステップにする。
3. 補助ファイル (`reference.md`, `scripts/*.sh` など) が必要なら同じディレクトリに作る。
4. リポジトリ規約を守る: 絵文字禁止、技術仕様書文体、kebab-case、表区切りはハイフン 3 つ。

### 3. TEST — テストが通るまで反復

生成したスキルを検証する。検証スクリプトを使う。

```
bash .claude/skills/skill-create/scripts/test-skill.sh <name>
```

このスクリプトは構造の妥当性 (frontmatter, description の有無, 命名規則) を検査する。
加えて、スキルの機能そのものを検証する代表タスクを 1 つ以上自分で考え、実際に実行して
期待結果が得られるか確認する。

- 失敗したら原因を特定し、SKILL.md または補助ファイルを修正し、再度テストする。
- 構造検査と機能検証の両方が通るまで反復する。最大 5 回試して通らなければ、
  何が通らなかったかを報告してユーザーに判断を仰ぐ。

### 4. MEMORIZE — レジストリに記憶

通過したスキルをレジストリに追記する。これが MUSE のメモリ部分にあたり、
次回の REUSE 段階で参照される。

[registry.md](registry.md) に 1 行追記する。形式:

```
| 日付 | スキル名 | 用途 | 検証したタスク |
```

追記後、ユーザーに対して次を報告する。

- 生成したスキル名とパス
- description (発火条件)
- 検証に使ったタスクと結果
- 今後の使い方 (`/<name>` または自動発火)

## 補足

- 既存スキルの改善版を作る場合 (variant) は、新ディレクトリではなく該当スキルを直接編集し、
  registry に「改善」として記録する。
- スキルの詳細仕様・雛形・命名規則は [reference.md](reference.md) を参照する。