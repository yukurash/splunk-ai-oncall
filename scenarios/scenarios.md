# 障害シナリオ（ground truth）

OpenTelemetry Demo の **feature flag** で注入する障害 6 種。
各シナリオは「正解（根本原因）」を事前に固定し、A/B の回答を突合して採点する。

> ⚠️ フラグ名・対象サービスは demo のバージョンで変わる。起動後に
> `opentelemetry-demo/src/flagd/demo.flagd.json` か Feature Flag UI で実在を確認し、
> 必要に応じてこの表を更新すること。

| # | feature flag | 想定症状（ユーザー影響） | 主に出る信号 | ✅ Ground Truth（根本原因） |
|---|---|---|---|---|
| 1 | `productCatalogFailure` | 特定商品の詳細でエラー、カート投入失敗 | product-catalog の span が ERROR、特定 product_id | product-catalog の GetProduct が特定 ID で失敗を返す |
| 2 | `paymentServiceFailure` | チェックアウトの決済が失敗 | checkout→payment の span が ERROR、charge 例外 | payment サービスの charge() が例外を投げる |
| 3 | `cartServiceFailure` | カートの取得/更新が失敗 | cart の span が ERROR、Redis 連携付近 | cart サービスが操作時にエラーを返す |
| 4 | `adServiceManualGc` | ページ表示が間欠的に遅い | ad サービスの p99 レイテンシ急増、GC 由来の停止 | ad サービスで強制 GC が走り長い stop-the-world |
| 5 | `recommendationServiceCacheFailure` | 時間とともにレコメンドが遅く/重く | recommendation のメモリ増・レイテンシ漸増 | recommendation の内部キャッシュが無制限に肥大 |
| 6 | `kafkaQueueProblems` | 注文後の処理が遅延・滞留 | Kafka consumer lag 増、accounting/fraud 系の遅延 | Kafka キューの詰まりで下流処理が遅延 |

## 各シナリオの「症状（ページに書く範囲）」

採点を公平にするため、A/B に渡す情報は **エンドユーザー視点の症状だけ**。サービス名や原因の示唆は書かない。

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
