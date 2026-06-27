# シナリオ1: productCatalogFailure

- flag: `productCatalogFailure` variant=on（targeting then=on / 商品 OLJCESPC7Z のみ失敗）
- 注入〜収集: 2026-06-27 04:5x JST（flagd 再起動で反映）/ 収集窓 -5m
- Ground Truth: **product-catalog の GetProduct が特定商品で失敗**（局所障害）
- 証拠: `evidence.json` / `evidence-compact.md`（product-catalog rootCauseErrorCount=229、rc_err 5本すべて product-catalog:ROOT_ERROR）

## 採点
| 観点 | A: Claude+MCP | B: 素のClaude |
|---|:--:|:--:|
| 根本原因サービス | ✅ product-catalog | ✅ product-catalog |
| 障害の性質 | ✅ 一部リクエストのみ失敗（波及と切り分け） | ✅ 特定商品の GetProduct 失敗 |
| 根拠 | **実データ**（rootCauseErr/トレース）で断定、postgresql除外 | **デモの事前知識**でフラグ名・商品IDまで断定 |
| 確信度 | 中〜高（フラグ名は未確認と正直に留保） | 高 |
| スコア(0-2) | **2** | **2** |

## 所見（記事の核）
- B は OTel Demo が有名な公開デモのため、**症状だけから記憶でフラグ名(productCatalogFailure)・商品ID(OLJCESPC7Z)まで“当てて”しまった**。＝事前知識による正解で、汎用性はない（自社の新規システムでは効かない）。
- A は**実データのみ**で根本原因サービスを正確に特定し、上流の波及エラーを切り分け、確証のない部分（具体トリガー）は留保。データに忠実で、未知システムでも再現する手法。
- 教訓: 「正解したか」だけでなく「**何を根拠にしたか**」で評価すべき。MCP(実データ)の価値は“汎用的に効く”点にある。

詳細な回答は `transcript-A.md` / `transcript-B.md`。
