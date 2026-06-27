# シナリオ6: kafkaQueueProblems（非同期キュー遅延 / consumer lag）

- flag: `kafkaQueueProblems` variant=on（Kafka 過負荷＋consumer 遅延で lag spike）
- 収集窓 -3m / Ground Truth: **Kafka コンシューマラグで注文後の非同期処理（accounting/fraud-detection/email）が遅延**
- 証拠: checkout は health=Ok/p99=30ms（producer なので即成功）。**APM一覧に kafka/accounting/fraud-detection が不在**。**checkout 36件に対し email req=1**（後続スループット崩壊）。kafka lag 自体は APM レイテンシには出ない。

## 採点
| 観点 | A: Claude+MCP | B: 素のClaude |
|---|:--:|:--:|
| 根本原因 | ✅ Kafka コンシューマラグ／非同期パイプライン滞留 | ✅ Kafka コンシューマラグ |
| 決定的証拠 | ✅ **email 1件/checkout 36件**の定量異常＋consumer の APM 不在を指摘 | （症状推論） |
| ノイズ除外 | ✅ payment Critical を残留と除外 | （対象外） |
| 確信度 | 中 | 中〜高 |
| スコア(0-2) | **2** | **2** |

## 所見（#5 との対比が重要）
- **#5（メモリリーク）は APM に信号ゼロ → A は断定不可**。一方 **#6（kafka lag）は間接的な観測可能効果（email スループット 1/36）があり、A はそれを掴んで A=2**。
- 教訓: 非同期/リソース系の障害でも、**下流に観測可能な効果が出ていればデータが効く**（#6）。出ていなければ専用メトリクスが要る（#5）。
- 補足: Kafka の lag メトリクスは **MCP で取得可能**（`gauge.kafka-max-lag`, `gauge.kafka.consumer.records-lag-max`）。固定 APM パックには含めなかったが、自律ツール選択ならこれを取りに行ける。
- B は「checkout=producer は成功、consumer が滞留」という構造推論で的中（デモ構成の知識）。
