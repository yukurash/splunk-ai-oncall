# 障害シナリオ（ground truth）

OpenTelemetry Demo **v2.2.0** の feature flag（`src/flagd/demo.flagd.json`）で注入する障害 6 種。
各シナリオは「正解（根本原因）」を固定し、A/B の回答を突合して採点する。

> フラグの実在は `opentelemetry-demo/src/flagd/demo.flagd.json` で確認済み（2026-06 時点）。
> バージョンが変わったら名前・変種を再確認すること。

| # | flag | 有効化の値 | 想定症状（ユーザー影響） | 主に出る信号 | ✅ Ground Truth（根本原因） |
|---|---|---|---|---|---|
| 1 | `productCatalogFailure` | `on`（targeting で商品 `OLJCESPC7Z` のみ） | 特定商品の詳細でエラー、その商品だけカート不可 | product-catalog の span が ERROR・product_id=OLJCESPC7Z | product-catalog の GetProduct が特定 ID で失敗 |
| 2 | `paymentFailure` | `100%`（変種はパーセント） | チェックアウトの決済が失敗 | checkout→payment の span が ERROR、charge 失敗 | payment の charge が一定割合で失敗（ここでは100%） |
| 3 | `cartFailure` | `on` | カートの取得/更新が失敗 | cart の span が ERROR（valkey 連携付近） | cart サービスが操作時にエラー |
| 4 | `adManualGc` | `on` | ページ表示が間欠的に遅い | ad サービスの p99 レイテンシ急増（GC 由来の停止） | ad サービスで強制フル GC による stop-the-world |
| 5 | `recommendationCacheFailure` | `on` | レコメンドが時間とともに重く/遅く | recommendation のメモリ漸増・レイテンシ増 | recommendation の内部キャッシュが無制限に肥大 |
| 6 | `kafkaQueueProblems` | `on` | 注文後の後続処理が遅延・滞留 | Kafka consumer lag 増、下流(accounting/fraud)の遅延 | Kafka キュー過負荷＋consumer 遅延で lag spike |

> ⚠️ #1 の `productCatalogFailure` は flagd の `targeting`（`if [cond, then, else]`）で
> 商品 OLJCESPC7Z のときだけ失敗する設計。単に `defaultVariant` を on にしても効かないため、
> `scripts/set-flag.ps1` は targeting の then 枝も書き換える。

## 各シナリオの「症状（ページに書く範囲）」

採点を公平にするため、A/B に渡すのは **エンドユーザー視点の症状だけ**。サービス名・原因の示唆は書かない。

- **#1**: 「一部の商品ページでエラーが出る、という問い合わせ。該当商品はカートに入れられない」
- **#2**: 「購入の最終確定で決済エラーになる、というクレームが複数」
- **#3**: 「カートが表示されない／更新できない、という報告」
- **#4**: 「サイト全体が時々もたつく。常にではなく、間欠的に遅い」
- **#5**: 「おすすめ表示が時間が経つほど遅くなる。再起動直後は速い」
- **#6**: 「注文は通るが、確認メール等の後続処理が遅れている様子」

## 採点ルール

- **正解(2)**: ground truth のサービス＋原因の種類まで一致。
- **部分(1)**: サービスは特定したが原因の種類を外した／逆。
- **不正解(0)**: 別サービスを原因と断定。
- あわせて **所要時間・トークン/コスト・対処提案の妥当性** を記録（`scripts/score.csv`）。
