# スコアカード（集計）

> 実験実行後に埋める。生データは各 `scenario-0X/` と `../scripts/score.csv`。

## 根本原因の正誤（2=正解 / 1=部分 / 0=不正解）

| # | 障害 | A: Claude + MCP | B: 素の Claude | 人間(筆者) |
|---|---|:---:|:---:|:---:|
| 1 | productCatalogFailure | – | – | – |
| 2 | paymentServiceFailure | – | – | – |
| 3 | cartServiceFailure | – | – | – |
| 4 | adServiceManualGc | – | – | – |
| 5 | recommendationServiceCacheFailure | – | – | – |
| 6 | kafkaQueueProblems | – | – | – |
| **合計 (/12)** | | – | – | – |

## 所要時間・コスト

| # | A 時間 | A ツール呼数 | A コスト($) | B 時間 | B コスト($) |
|---|---|---|---|---|---|
| 1 | – | – | – | – | – |
| … | | | | | |

## ひとことメモ（誤診・面白かった点）

- #X: …
