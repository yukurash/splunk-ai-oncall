# シナリオ2: paymentFailure（決済100%失敗）

- flag: `paymentFailure` variant=100%（charge を全件失敗）
- 収集窓 -4m / Ground Truth: **payment の charge が失敗（checkout 経由で決済エラー）**
- 証拠: payment health=Critical / err=4 / rcErr=4、**rc_err トレース 4/4 が rootCause=[payment]（checkout フロー起点）**。payment は低トラフィック（checkout時のみ）。

## 採点
| 観点 | A: Claude+MCP | B: 素のClaude |
|---|:--:|:--:|
| 根本原因サービス | ✅ payment | ✅ payment |
| ノイズ切り分け | ✅ flagd/local-llm の Critical を「rc_err 経路に無関係」と除外 | （データ無しのため対象外） |
| 確信度 | **高**（rc_err 4/4＋payment Critical＋p99≈450s=ハング） | 中〜高 |
| スコア(0-2) | **2** | **2** |

## 所見
- サービス表には payment 以外にも flagd.evaluation / local-llm が **Critical** と出るノイズがあったが、**A は rc_err トレース（全件 checkout→payment）で本当の震源を切り分けた**。複数 Critical の現場で「どれが本物か」を実データで判断できる点が MCP の価値。
- B は症状（決済確定でエラー）から payment＋フラグ名を断定（デモ知識）。決済エラー→payment は症状から自明な部類で、ここは差が出にくい。
- 低トラフィックでも Splunk の rootCauseErrorCount / rc_err トレースで根本原因を特定できることを確認。
