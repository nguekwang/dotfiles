---
name: gform-url-generator
description: >-
  Googleフォームの回答を事前入力(prefill)した状態で開けるURLを、クエリパラメータ
  (entry.XXXXXXXXX, usp=pp_url)付きで生成する。silver-lake/util/gform-url-generator.html
  を参照実装として使う。ユーザーがGoogleフォームの事前入力URL・プリフィル済みURLを
  作りたいとき、またはフォームのentry IDを調べたいときに使う。
---

# gform-url-generator

Googleフォームの viewform URL に対して、各設問の回答をあらかじめ入力した状態で
開けるURL(prefilled URL)を組み立てる。フォーム内部の entry.XXXXXXXXX という
フィールドIDをクエリパラメータとして付与することで実現する。

参照実装: [silver-lake/util/gform-url-generator.html](../../../silver-lake/util/gform-url-generator.html)
(フォームのページソースから `FB_PUBLIC_LOAD_DATA_` を抽出し、entry ID・設問タイプ・
選択肢を自動検出してURLを組み立てるツール)

## 手順

1. 対象フォームの回答用URL(viewform)を用意する。編集用URL(末尾が `/edit`)しか
   無い場合は `/edit` を `/viewform` に置き換える。
2. ブラウザでそのviewform URLを開き、ページソースを表示(Ctrl+U)して全選択・
   コピー(Ctrl+A → Ctrl+C)する。
3. `silver-lake/util/gform-url-generator.html` をブラウザで開く。
   - ステップ1の入力欄にviewform URLを貼り付ける。
   - ステップ2の入力欄に2.でコピーしたページソースを貼り付け、「解析」を押す。
   - 設問が検出されると「N 個のフィールドを検出」と表示され、設問ごとの
     entry.ID・ラベル・型・選択肢一覧がカード表示される。
4. 検出された各設問に、事前入力したい回答値を型に応じて入力する。
   - text: 文字列をそのまま入力する。
   - radio: 表示された選択肢の文字列と完全一致する値を入力する。
   - checkbox: カンマ区切りで複数値を入力する(各値が独立した `entry.ID` として
     付与される)。
   - date: 年・月・日を個別欄に入力する(`entry.ID_year` / `_month` / `_day` として
     付与される)。
   - time: 時・分を個別欄に入力する(`entry.ID_hour` / `_minute` として付与される)。
   - 検出に無い設問へ後から回答を足したい場合は、末尾の「entry.XXXXXXXXX を追加」欄に
     entry IDを入力して「+ 追加」する。
5. 「URLを生成」を押すと、`<viewform URL>?usp=pp_url&entry.ID1=値1&entry.ID2=値2...`
   の形式でURLが生成される。「コピー」でクリップボードに取得できる。
6. ツールが使えない場合(ページソースを貼れない、ブラウザが無い等)は、次の形式で
   手動組み立てる。
   - entry.ID はページソース中の `name="entry.XXXXXXXXX"` を検索して調べるか、
     開発者ツールで該当の入力欄を inspect して調べる。
   - URL形式: `<viewform URL>?usp=pp_url&entry.<ID1>=<値1>&entry.<ID2>=<値2>...`
   - 値に日本語・記号を含む場合はURLエンコードする(`encodeURIComponent` 相当)。

## 補足

- entry.ID はフォーム作成者が設問を削除・再作成すると変わる。共有前に生成した
  URLを実際に開き、意図した値が事前入力されているか確認すること。
- checkboxで複数値を渡す場合、同じ `entry.ID` を複数回クエリパラメータに
  含める(1つの値にカンマ区切りで詰め込まない)。
- `usp=pp_url` はGoogle側でこのURLがプリフィル済みURLであることを示すパラメータで、
  省略しても事前入力自体は機能するが、慣例として付与する。
