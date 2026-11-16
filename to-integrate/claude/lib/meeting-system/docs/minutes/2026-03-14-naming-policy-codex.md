# Meeting: naming-policy

- Date: 2026-03-14
- Tools: Codex
- Participants: User, AI tools
- Topic: naming-policy
- Objective: Terraform 中心の命名規則について、命名要素と検証方法の方針を決める

## Agenda

- Terraform を中心にした命名規則の統一方針を整理する
- 命名に含める要素と階層の切り方を議論する
- 命名規則の検証方法を整理する

## Summary

Terraform module ごとに揺れている命名規則を統一するため、まず Terraform コード内識別子とクラウド実リソース名を分けて扱う方針が整理された。初期案としては、コード内は `snake_case`、実リソース名は `kebab-case` とし、実リソース名には少なくとも `service`, `env`, `purpose` を含める方向が確認された。

その後、例外を前提に規約を作るよりも、そもそも例外が発生しにくいように命名に含める意味の階層やカテゴリを MECE に整理すべき、という論点が追加された。これを受けて、`purpose` のような曖昧な要素をそのまま使うのではなく、`component` と `role` に分解し、命名対象ごとにどの階層まで名前に含めるかを固定する方がよい、という方向で整理された。また、検証も単なる文字種チェックではなく、意味階層の許可値をチェックする二段構えにすべき、という認識で一致した。

## Context

ユーザーは会議モードでの進行を指定し、会議名を `naming-policy`、目的を「命名規則を決める」、背景を「module ごとに揺れている」、制約を「Terraform 中心」、決めたいことを「命名要素と検証方法」とした。進め方として、役割別の発言を行い、最後に `Decisions`, `Open Questions`, `Action Items` を Markdown で整理することが求められた。

会議の途中でユーザーから、「そもそも例外が発生しないように MECE に階層やカテゴリを分けたら良いのでは？」という論点が追加され、命名要素の定義方法そのものを見直す議論に移った。

## Discussion

### User

- Terraform 中心で、module ごとに揺れている命名規則を整理したい。
- 命名要素と検証方法を決めたい。
- 例外運用ありきではなく、例外が出ないように MECE に階層やカテゴリを分けるべきではないか、という問題提起があった。
- 会議の最後は保存しやすい Markdown の議事録としてまとめることが求められた。

### PM

- 命名規則の目的は可読性だけでなく、運用事故の予防とレビュー効率の向上にある。
- ルールの適用対象として、少なくとも `module`, `resource`, `variable`, `output`, `locals`, `workspace/env`, `tag/label` を視野に入れるべきと整理された。
- 厳密すぎる規約は守られなくなるため、必須項目と推奨項目を分ける必要がある。
- 後半の議論では、命名規則は単なる表記ルールではなく情報設計であり、先に識別したい意味の層と並び順を決めるべきだと整理された。
- 命名対象ごとに、どのレベルの識別情報を名前に持たせるかを定義する方が、例外申請を減らせるという観点が示された。

### Dev

- Terraform では、コード内識別子、クラウド上の実リソース名、共通タグやラベルは同一ルールで扱わない方がよいと整理された。
- 初期案として、Terraform の `module`, `resource`, `data`, `variable`, `output`, `locals` は `snake_case` を基本とする案が出た。
- 実リソース名はクラウド制約に寄せて `kebab-case` を基本とし、短いハイフン連結が扱いやすいとされた。
- 実リソース名に含める初期候補として、`system` または `service`、`module` または `resource kind`、`environment`、`region`、`instance suffix` が挙げられた。
- 最小構成として `service-env-purpose` のような形が例示されたが、`purpose` は曖昧さが残るという課題も見えた。
- MECE の観点から、命名要素は `domain`, `system`, `component`, `resource_role`, `environment`, `region`, `instance` のように意味の階層へ分解した方がよいという案が出た。
- すべての要素を毎回名前に含めるのではなく、命名対象ごとにどの階層まで使うかを固定する方針が示された。
- `purpose` をそのまま使うのではなく、可能な限り `component` と `role` に分解して扱う方が、分類として一貫すると整理された。

### Ops

- 運用上は、名前から「どのサービスか」「どの環境か」「何用途か」「必要ならどのリージョンか」が判別できることが重要とされた。
- クラウドによる文字数制限や使用可能文字の差を踏まえ、共通ルールは安全側に寄せるべきとされた。
- 実リソース名については、英小文字のみ、区切りは `-`、原則 `-` 以外の記号は使わない、先頭末尾は英数字、独自の長さ上限を決める、`environment` は省略しない、free-form な略語を禁止する、という案が出た。
- `environment` の表記揺れを防ぐため、`dev`, `stg`, `prod` に固定する案が整理された。
- 後半では、`purpose` のような曖昧語よりも `component` と `role` に分解した方が運用上も扱いやすく、例外が減るという見方が示された。
- 実リソース名の構造として `<system>-<component>-<role>-<env>[-<region>][-<instance>]` のような形が例示された。

### Reviewer

- 命名規則は人間レビューだけに依存させず、静的チェック、CI チェック、レビュー観点の明文化を組み合わせるべきとされた。
- Terraform 中心の検証手段として、`tflint` の custom rule や命名ルール拡張、`conftest` + `OPA` による HCL または plan の検証、`pre-commit` によるローカル実行、CI での必須化が候補に挙がった。
- Terraform コード内識別子と実リソース名は、同じ名前でもチェックすべき観点が異なるため、別ルールで検証すべきとされた。
- 例外を許可する場合は、既存リソースとの互換性維持、外部システム制約、クラウドサービス固有制約、import 済み legacy resource など、理由を明記して管理すべきという案が出た。
- MECE 議論を受けて、検証を「構文検証」と「意味検証」に分けるべきという整理が加わった。
- 構文検証では `kebab-case`、長さ、禁止文字などを見て、意味検証では `env` の許可値、`role` の定義済みカテゴリ、`component` の登録済み名などをチェックする、という二段構えが提案された。

## Decisions

- Terraform コード内識別子と実リソース名は別ルールで管理する。
- Terraform の `module`, `resource`, `variable`, `output`, `locals` は `snake_case` を基本とする。
- 実リソース名は `kebab-case` を基本とし、英小文字・数字・`-` のみ許可する。
- 環境表記は `dev`, `stg`, `prod` に固定する。
- 命名規則は表記ルールより先に、名前に含める意味の階層を定義する。
- 例外前提で規約を作るのではなく、例外が出にくい MECE な分類軸を先に定義する。
- `purpose` は曖昧なため、可能な限り `component` と `role` に分解して扱う。
- 命名対象ごとに、名前に含める階層の深さを固定する。
- 命名規則の検証は、ローカルと CI の両方で実施する。
- 検証は「構文検証」と「意味検証」に分ける。
- 検証手段の第一候補は `pre-commit` + `tflint` + `conftest/OPA` とする。

## Open Questions

- `service` を正式な基準名として残すか、`system` と `component` に分解して置き換えるか。
- 階層の最上位として `domain` が必要か、それとも `system` 起点で十分か。
- `component` と `role` の境界をどう定義するか。
- 実リソース名の階層として `region` を常に含めるか、マルチリージョン時のみ必須にするか。
- Terraform module 名とクラウド実リソース名で、同じ階層モデルを使うか。
- AWS 以外の provider も同一規則で運用するか。
- 許可値辞書や例外管理をどこで管理するか。コード、YAML、OPA policy、ADR のどれを基準にするか。
- 既存の命名揺れを一括リネームするか、変更時のリファクタリングで段階対応するか。

## Action Items

- 担当者: PM
- 内容: 命名対象のスコープを確定し、各対象で必要な識別情報を棚卸しする。
- 期限: TBD

- 担当者: Dev
- 内容: Terraform 識別子向けの `snake_case` ルール案と OK/NG 例を作成する。
- 期限: TBD

- 担当者: Dev
- 内容: 既存命名で `purpose` を使っている例を洗い出し、`component` / `role` に再分類する。
- 期限: TBD

- 担当者: Ops
- 内容: 実リソース名の共通制約案を作成し、文字種、長さ、環境表記、略語一覧を整理する。
- 期限: TBD

- 担当者: Ops
- 内容: 実運用で必要な識別軸を整理し、必須階層と任意階層を分ける。
- 期限: TBD

- 担当者: Reviewer
- 内容: `pre-commit`, `tflint`, `conftest/OPA` を使った構文検証と意味検証の分離案を作成する。
- 期限: TBD

- 担当者: 全員
- 内容: 既存 module やリソースから命名揺れの実例を収集し、提案した階層モデルで一意に分類できるか確認する。
- 期限: TBD

- 担当者: 全員
- 内容: 例外ルールと legacy 移行方針を持ち寄る。
- 期限: TBD

## References

- [template.md](template.md)
- [README.md](README.md)
- [MEETING-PROTOCOL.md](MEETING-PROTOCOL.md)
- [naming-conventions-as-iac.md](../../../../../notes/tech/naming-conventions-as-iac.md)
