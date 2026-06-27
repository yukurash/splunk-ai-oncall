# スコアカード（集計）

> 実験実行後に埋める。生データは各 `scenario-0X/` と `../scripts/score.csv`。

## 根本原因の正誤（2=正解 / 1=部分 / 0=不正解）

| # | 障害 | A: Claude + MCP | B: 素の Claude | 備考 |
|---|---|:---:|:---:|---|
| 1 | productCatalogFailure | **2** | **2** | 両者 product-catalog を特定。A=実データ根拠／B=デモ事前知識（汎用性なし） |
| 2 | paymentFailure | – | – | |
| 3 | cartFailure | – | – | |
| 4 | adManualGc | – | – | （実行中） |
| 5 | recommendationCacheFailure | – | – | |
| 6 | kafkaQueueProblems | – | – | |
| **合計 (/12)** | | – | – | |

## 所要時間・コスト

| # | A 時間 | A ツール呼数 | A コスト($) | B 時間 | B コスト($) |
|---|---|---|---|---|---|
| 1 | – | – | – | – | – |
| … | | | | | |

## ひとことメモ（面白かった点）

- **#1 priors vs evidence**: B(ツールなし)は OTel Demo が有名な公開デモのため、症状だけから記憶でフラグ名(`productCatalogFailure`)・商品ID(`OLJCESPC7Z`)まで“当てて”しまった。A(MCP)は実データのみで product-catalog を根本原因と特定し、上流の波及を切り分け、確証のない部分は留保。→「正解したか」より「**何を根拠にしたか**」で評価すべき。MCP の価値は**未知システムでも汎用的に効く**点。
- 採点ルール補足: 本実験は**回答者を“正解を知らないまっさらな Claude サブエージェント”**にして公平化。A には固定プロトコルで中立収集した実APMデータのみ渡した。
