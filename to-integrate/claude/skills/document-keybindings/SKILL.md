---
name: document-keybindings
description: >-
  このユーザーの環境(Hyprland, foot, qutebrowser, Neovim)のキーバインドを、各設定ファイルから
  決定的なスクリプトで抽出し、silver-lake/dev/keybindings.md と HTML Artifact の2形式で説明書として
  生成する。LLMは対象ファイルの取りこぼし確認と出力提示にのみ使う。ユーザーがキーバインド一覧・
  ショートカット一覧・キーバインドの説明書の作成や更新を依頼したときに使う。
---

# document-keybindings

このユーザーの環境のキーバインドを、設定ファイルから機械的に抽出して一覧化する。
`keybindings-help` スキル(Claude Code自身の `~/.claude/keybindings.json` の話)とは対象が異なり、
重複しない。

## 手順

1. 対象ファイルが存在するか確認する。

   | ソース | パス | パーサが理解する形式 |
   | --- | --- | --- |
   | Hyprland | `user/hypr/hyprland.lua` | `hl.bind(main .. " + ...", ..., { description = "..." })` |
   | foot | `user/hypr/foot.ini` | `[key-bindings]` セクションの `action=Combo` |
   | qutebrowser | `user/browsers/qutebrowser.py` | `config.bind('<key>', 'command'[, mode=...])`、ファイル内の `map(key, command)` ヘルパー、`for m in [...]:` ブロックの `mode=m` |
   | Neovim | `user/nvim/init.lua` | `vim.keymap.set("mode", "key", rhs, { desc = "..." })` |

   この一覧は `environment-assumptions` スキルが挙げる設定ファイル配置(`user/`, `etc/`)と一致している。
   新しい設定ファイル(例: Waybarのクリックアクション、fcitx5のキーバインド設定)が増えた、または
   既存ファイルの記法が変わった場合は、スクリプトを直すかどうかをここで判断する。これが
   このスキルで唯一 LLM の判断を要する箇所であり、他は決定的なスクリプトに任せる。

2. 抽出・レンダリングを1コマンドで実行する。LLMの読解は介さない。

   ```bash
   python3 .claude/skills/document-keybindings/scripts/extract-keybindings.py \
     <repo_root> silver-lake/dev/keybindings.md <html出力先>.html
   ```

   このスクリプトが4ソースすべてをパースし、`silver-lake/dev/keybindings.md` と HTML 版を同時に書き出す。
   抽出件数がソースごとに標準出力される。

3. 件数が直前の実行や設定ファイルの行数と大きく違わないか目視確認する(パーサが取りこぼしていないか
   の最終チェック)。

4. HTML版を Artifact として公開する(`title`: キーバインド便覧、絵文字favicon)。既に公開済みの
   Artifact を更新する場合は、その `url` を指定して同じ手順で再公開する。

## 補足

- このスクリプトは正規表現と括弧の対応付けだけで動く。対象ファイルがPython/Luaとして動的に
  バインドを組み立てている場合、スクリプトが個別に対応している構文(上記の表)以外は捕捉しない。
  未対応の構文を追加したときは `reference.md` の「既知の限界」に追記し、パーサを拡張する。
- fcitx5 (`user/fcitx5/*.conf`) は現時点でキーバインド定義を含まないため抽出対象に含めていない。
  将来 fcitx5 側にキーバインド設定が追加されたら、このスキルとスクリプトを見直す。
- 詳細なパース仕様・既知の限界は [reference.md](reference.md) を参照する。
