# Meeting: action-management

- Date: 2026-03-14
- Tools: Codex
- Participants: all
- Topic: action-management
- Objective: 会議で発生した TODO をもれなく Issue 化する仕組みを作る

## Agenda

- 会議起点 TODO の Issue 化漏れを防ぐ運用を決める
- `gh` コマンドによる起票フローの最小構成を定める
- 完了条件と未決事項を整理する

## Current Focus

- 会議で出た TODO を構造化して記録し、会議終了時に `gh` で確実に Issue 化する最小運用の定義

## Summary

会議起点の TODO を漏れなく GitHub Issue に変換するため、まずは高度な自動化ではなく、会議中に TODO を構造化して記録し、会議終了時に `gh` で確実に起票する運用を第一候補とする方針で合意した。

重要論点は、TODO 抽出漏れの防止、起票責任の明確化、必須項目の標準化、重複起票や認証不備の運用対策だった。

## Context

ユーザーは会議モードでの進行を指定し、会議名を `Action management`、目的を「会議で発生したTODOをもれなくIssuするシステムを作ること」、制約を「Issueへの起票はghコマンドで実施する」、参加者を `all` とした。

進め方として、役割別に発言すること、参加者に含まれる agent の視点を優先すること、ランニングメモを維持すること、脱線論点は `Parking Lot` に退避すること、`Current Focus` を明示すること、最後に `Decisions`, `Open Questions`, `Action Items` を必ず出すことが求められた。

## Discussion

### User

- 会議で発生した TODO を漏れなく Issue 化できる仕組みを作りたい。
- Issue 起票は `gh` コマンドで実施する制約がある。
- 会議形式として、役割別の発言、ランニングメモ、`Parking Lot`、`Current Focus`、`Decisions / Open Questions / Action Items` の整理が求められた。

### agent

- 難所は「TODO 抽出漏れ」と「Issue 起票の運用崩れ」であり、先に入力フォーマットと責任分界を決める必要がある。
- 先に固定すべき論点は、TODO の発生源、Issue 変換の責任主体、`gh issue create` を実行するタイミング、Issue 化対象の最小必須項目の4点である。
- 現実的な第一候補として、会議中にランニングメモへ TODO を構造化して蓄積し、会議終了時に agent がまとめて `gh` で起票する方式を提示した。

### PM

- 完璧な自動化よりも、漏れない標準手順を先に作るべきと整理した。
- Issue として機能させるため、各 TODO に最低でも `title / owner / due / source meeting` が必要だとした。

### Dev

- 入力フォーマットを固定すれば、後段の自動起票は実装容易であると整理した。
- 会議メモ中で TODO を機械可読に記録し、後で `gh issue create --title ... --body ... --label ...` に変換する案を示した。

### Ops

- 運用上の主要リスクとして `gh` 認証切れと重複起票を挙げた。
- 起票前に `gh auth status` と、同一 meeting ID を含む既存 Issue の存在確認を入れるべきとした。

### Reviewer

- 「会議メモに TODO がある」だけでは完了ではなく、「全 TODO が Issue URL と紐づいた」状態を完了とみなすべきとした。
- Issue 化の Definition of Done を明文化する必要があると整理した。

## Proposed Operating Flow

1. 会議中に TODO を定型フォーマットでランニングメモへ記録する。
2. 会議終了時に TODO 一覧を確認し、不足項目を補完する。
3. agent が `gh issue create` を使って 1 件ずつ起票する。
4. 起票後、Issue URL を会議メモへ追記する。
5. TODO と Issue の対応が 100% 取れていることをもって会議アクション管理完了とする。

## TODO Template Draft

```md
TODO:
- title: <やること>
  owner: <担当者>
  due: <期限 or 未定>
  source_meeting: Action management / 2026-03-14
  labels: meeting, action-management
  body: <背景・補足>
```

## Running Memo

### Confirmed

- 目的は「会議起点 TODO の Issue 化漏れ防止」
- 制約は「Issue 起票を `gh` コマンドで実施」
- 第一候補は「会議中に構造化記録、会議終了時にまとめて起票」
- 運用リスクは「抽出漏れ」「認証不備」「重複起票」
- 完了条件候補は「全 TODO が Issue 化され、Issue URL が会議メモに残ること」

### Parking Lot

- 音声認識や議事録自動要約の導入
- Jira 等との二重管理
- 高度な Issue 自動分類やテンプレート展開

## Decisions

- TODO の Issue 化は、まず運用で確実に回る最小構成から始める。
- 会議中に TODO を構造化して記録する方式を採用候補の第一とする。
- Issue 起票は `gh` コマンドで行う。
- 会議完了の定義として、「会議内 TODO と Issue の対応が取れていること」を重視する。
- 必須項目のベースは `title / owner / source meeting` とし、`due` は要件確定対象とする。

## Open Questions

- Issue 起票の責任者を常に agent に固定するか。
- `due` を必須項目にするか任意項目にするか。
- 起票は会議終了時にまとめて行うか、一部を会議中に逐次行うか。
- ラベル命名規則をどう設計するか。
- `source meeting` の一意な識別方法をどうするか。

## Action Items

- 担当者: agent
- 内容: TODO 記録テンプレートを正式化する。
- 期限: TBD

- 担当者: PM
- 内容: Issue 必須項目の業務要件を確定する。
- 期限: TBD

- 担当者: Ops
- 内容: `gh` 実行前チェック項目を定義する。
- 期限: TBD

- 担当者: Reviewer
- 内容: Issue 化完了の Definition of Done を文章化する。
- 期限: TBD

## References

- [README.md](README.md)
- [template.md](template.md)
- [MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
