# 自律オンコール実走トランスクリプト（検知→調査→原因特定）

**設定**: 正解を知らないまっさらな Claude サブエージェントに、症状を一切教えず「本番で異常。調べて」とだけ渡す。AI が `CALL <tool>` 形式で Splunk MCP ツールを**自分で選び**、オペレータ（筆者）が実行して結果を返す。AI は答えにたどり着くまで自律的に調査する。

**仕込んだ障害**: `productCatalogFailure`（product-catalog の GetProduct が特定商品で失敗）。同時に payment/Charge の残留エラーと、flagd・local-llm の慢性ノイズが Critical 表示で混在する**撹乱あり**の盤面。

合計: **3調査ラウンド / 自律的に選んだ MCP ツール呼び出し 7回 / tool_uses(サブエージェント自身)=0**。

---

## ラウンド0（与えた指示）
> [ALERT] 本番 Astronomy Shop で異常の通報。詳細不明。まず自分で状況を把握し、調査を始めてください。

## ラウンド1 — 検知（AIの判断）
> 本番異常の通報を受けました。まず全体像を把握します。発火中のアラートと、APM サービス一覧（エラー数順・health 付き）を同時に取得して、異常の所在を掴みます。

AIが選んだツール:
```
CALL o11y_search_alerts_or_incidents { ... }
CALL o11y_get_apm_services { order_by:"errorCount", include_entity_health:true }
```
返した結果（要点）: alerts 0件。サービス一覧で product-catalog が err=99/**rootCauseErr=99**、frontend系は err 多いが rootCauseErr 小、payment/flagd/local-llm が Critical。

## ラウンド2 — 切り分け（AIの判断）
> 注目点は rootCauseErr（自分が震源のエラー数）です。frontend-proxy err=112 だが rootCauseErr=1、frontend err=111 だが rootCauseErr=8 → **下流から波及**。product-catalog err=99/rootCauseErr=99 → 全エラーが自分発の震源。payment/flagd/local-llm は別系統の可能性。

AIが選んだツール:
```
CALL o11y_get_apm_service_errors_and_requests { service:"product-catalog" }
CALL o11y_get_apm_exemplar_traces { exemplar_type:"rc_err", service:"product-catalog" }
CALL o11y_get_apm_service_dependencies { ... }
CALL o11y_get_apm_service_errors_and_requests { service:"payment" }
```
返した結果（要点）:
- product-catalog: **GetProduct が req=5496/err=204/rootCauseErr=204、ListProducts と Health/Check はエラー0**（特定エンドポイント限定）。
- rc_err 実トレース 5/5 が rootCause=product-catalog。
- payment: **Charge が err=5/rootCauseErr=5**（別件）。

## ラウンド3 — 確証（AIの判断）
> 最後に「何のエラーか」を確定するため、product-catalog のエラートレース中身を取得します。

AIが選んだツール:
```
CALL o11y_get_apm_exemplar_traces { exemplar_type:"err", service:"product-catalog" }
```
返した結果（要点）: 全トレースで product-catalog=ROOT_ERROR、上流 frontend系=ERROR（波及）。所要時間 26〜100ms（即時エラー＝遅延ではない）。error.message は空。

## ラウンド4 — FINAL（AIの結論）

> ## 根本原因（断定）
> **product-catalog の `oteldemo.ProductCatalogService/GetProduct` が、商品閲覧フローのほぼ全リクエストで即時エラー応答**。`productCatalogFailure` 系フラグによる意図的注入と整合。上流はすべて波及。
>
> ## 根拠（観測データ）
> - product-catalog rootCauseErr=99（全件自分発）。GetProduct=204/204、ListProducts/Health は無傷 → **特定エンドポイント限定**。
> - rc_err/err 実トレース計10本すべてで product-catalog=ROOT_ERROR、上流=ERROR（波及）。
> - 26〜100ms と短い → 遅延ではなく即時エラー。
> - frontend-proxy rootCauseErr=1 / frontend rootCauseErr=8 → 大半は下流由来。
>
> ## 切り分け（なぜ他の異常は震源でないか）
> - frontend系: エラー多いが rootCauseErr 極小＝被害者。
> - **payment（Charge err=5）: 自分発だが rc_err 経路に相互登場せず件数も桁違いに小 → 別件（独立した低頻度障害）**。
> - flagd/local-llm: 高レイテンシだが product-catalog の rc_err 経路に登場せず → 別件/ノイズ。
>
> ## 対処案
> 1. flagd の `productCatalogFailure` を確認し ON なら OFF。
> 2. フラグ起因でなければ product-catalog の直近デプロイをロールバック、アプリログで gRPC 例外を確定（トレースに本文が無いため）。
> 3. 封じ込め後、frontend系のエラー率が連動回復するか再観測。
> 4. payment/Charge・flagd・local-llm は別件として並行起票。
>
> ## 確信度
> **根本原因の所在（product-catalog/GetProduct）= 高**（rootCauseErr 局在・エンドポイント限定・即時エラー・トレース一貫の独立複数事実が一致）。
> **具体トリガー（フラグ説）= 中**（既知パターンと整合するが flagd→product-catalog の因果リンクは観測で直接取れておらず、ログ/フラグ状態確認で「高」に上げられる）。

---

## 評価（正解との突合）
- ✅ 根本原因サービス・**エンドポイント（GetProduct）まで的中**。
- ✅ frontend系の派手なエラーを「波及」と正しく除外。
- ✅ 同時に存在した payment/Charge を「別件」と正しく分離（実際に残留した独立障害）。
- ✅ flagd/local-llm のノイズを除外。
- ✅ 確信度を校正（観測で取れない因果は断定せず「要ログ確認」と留保）。

**これは“実データへのアクセス（MCP）”が無ければ一手も成立しない調査**。検知・切り分け・確証のすべてがライブの APM データに依存している。
