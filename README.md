# splunk-ai-oncall

**AI にオンコールを任せたら、どこまで障害の根本原因にたどり着けるのか？**

[OpenTelemetry Demo（Astronomy Shop）](https://github.com/open-telemetry/opentelemetry-demo) にわざと障害を注入し、Splunk Observability Cloud に流れるテレメトリを **Splunk MCP サーバー経由で Claude に渡して、自律的に根本原因を特定させる** 実験リポジトリです。

検証したい問いはひとつ。

> **「ライブな観測データへのアクセス（MCP）は、AI の障害診断を本当に賢くするのか？」**

同じモデルの Claude を、2 パターンで同じ障害に挑ませて採点します。

| | 観測データへのアクセス | やること |
|---|---|---|
| **A: Claude + Splunk MCP** | あり（MCP で実データを調査） | アラートを起点に自律調査し、根本原因を特定 |
| **B: 素の Claude** | なし（アラート文だけ） | 推論だけで根本原因を当てにいく |

> Zenn コンテスト「Splunk OpenTelemetry 2026」投稿作品の検証コードです。記事リンクは公開後に追記します。

## アーキテクチャ

```
 ┌─────────────────────┐     OTLP      ┌──────────────────────┐   sapm/signalfx/hec   ┌───────────────────────────┐
 │  OpenTelemetry Demo │ ───────────▶ │ OTel Collector       │ ───────────────────▶ │ Splunk Observability Cloud│
 │  (Astronomy Shop)   │  trace/metric │ (contrib, demo同梱)  │                       │  APM / Metrics / Logs      │
 │  + Feature Flags    │  /log         │ + Splunk exporters   │                       └────────────┬──────────────┘
 └─────────────────────┘               └──────────────────────┘                                    │ X-SF-REALM / X-SF-TOKEN
        ▲ 障害注入(flagd)                                                                            ▼  (Splunk MCP gateway)
        │                                                                              ┌───────────────────────────┐
        └──────────────────────────────────  採点 ◀──────────────────────────────────│  Claude Code  ⇄  MCP tools │
                                                                                       └───────────────────────────┘
```

## リポジトリ構成

```
splunk-ai-oncall/
├─ docker-compose.splunk.yml      OTel Demo に被せる Splunk 連携オーバーレイ
├─ collector/
│   └─ otelcol-config-extras.yml  Demo の Collector に足す Splunk exporter 設定
├─ scenarios/scenarios.md         障害6種：feature flag・症状・正解(ground truth)
├─ prompts/
│   ├─ oncall-system.md           オンコール・エージェント(A)のシステムプロンプト＆調査手順
│   └─ alert-template.md          A/B に同一文面で渡す「ページ（呼び出し）」テンプレ
├─ scripts/
│   ├─ set-flag.ps1 / .sh         feature flag をトグル
│   ├─ run-scenario.ps1           注入→計測開始→スナップショット補助
│   └─ score.csv                  採点表（機械可読）
├─ results/
│   ├─ scenario-01..06/           A/B のトランスクリプト・スクショ・時間・コスト
│   └─ scorecard.md               集計表（記事の山場）
└─ article/draft.md               Zenn 記事ドラフト（日本語）
```

## 必要なもの

- Docker / Docker Compose（OTel Demo は RAM 6GB 程度を推奨）
- Node.js 18+（Claude Code / `npx` 用）
- [Claude Code](https://claude.com/claude-code)
- **Splunk Observability Cloud アカウント**（[14日無料トライアル](https://www.splunk.com/en_us/download/o11y-cloud-free-trial.html) でOK）
  - ⚠️ Splunk MCP は **GCP / GovCloud 系 realm では使えません**。登録時に **AWS 系 realm（`us0` / `us1` / `eu0` など）** を選んでください。
  - これは Splunk のデータセンターを選ぶだけの話で、**AWS アカウントは不要**・AWS 側の構築や課金は一切ありません。

## クイックスタート

### 1. Splunk トライアル登録 → realm と API トークンを取得
- [Observability Cloud のトライアル](https://www.splunk.com/en_us/download/o11y-cloud-free-trial.html)に登録（AWS 系 realm を選択）。
- **API アクセストークン**を発行：Settings → Access Tokens →（デフォルトの API トークン or 新規発行）。
- ログ用に **HEC トークン**も控える（任意。トレース/メトリクスだけでも実験は可能）。

### 2. `.env` を用意
```bash
cp .env.example .env
# .env を開いて SPLUNK_REALM / SPLUNK_ACCESS_TOKEN などを記入
```

### 3. OTel Demo を取得して Splunk 連携を被せる
（動作確認: demo **v2.2.0** / collector contrib **0.151.0**）
```bash
git clone https://github.com/open-telemetry/opentelemetry-demo.git
# Splunk exporter 設定を demo の extras に上書き
cp collector/otelcol-config-extras.yml opentelemetry-demo/src/otel-collector/otelcol-config-extras.yml

cd opentelemetry-demo
# .env の SPLUNK_* をシェルにエクスポート（demo 自身の .env は既定で使われる）
set -a; . ../.env; set +a
# Splunk を唯一のバックエンドにする軽量構成（ローカル Jaeger 等は起動しない）
docker compose -f compose.yaml -f ../docker-compose.splunk.yml up -d
```
> compose ファイルは `compose.yaml`。観測スタックも併用したい場合は `-f compose.observability.yaml` を足し、extras の pipeline に jaeger/prometheus/opensearch の exporter 名も加える。
> PowerShell なら `set -a; . ../.env; set +a` の代わりに各 `SPLUNK_*` を `$env:` で設定してから起動。

### 4. Splunk にデータが流れることを確認
- Demo の Web UI: <http://localhost:8080>
- Splunk O11y の **APM** に Astronomy Shop の各サービス／トレースが、**Metrics Finder** にメトリクスが出ていれば疎通OK。

### 5. Claude Code に Splunk MCP を接続
`.mcp.json`（公式 `mcp-remote` 経由）を同梱。`${SPLUNK_*}` は環境変数から展開されるので、
リポジトリ直下で env をエクスポートしてから Claude Code を起動する：
```bash
set -a; . ./.env; set +a
claude              # プロジェクトの .mcp.json が読まれる
claude mcp list     # splunk-o11y が connected になればOK
```
> MCP gateway URL は realm 依存。例: **jp0(Tokyo) → `https://region-tyo10.api.scs.splunk.com/system/mcp-gateway/v1/`**。
> 対応表は [Splunk 公式](https://help.splunk.com/en/splunk-cloud-platform/mcp-server-for-splunk-platform/1.1/configure-splunk-observability-tools-with-splunk-mcp-server)。GCP/GovCloud realm は非対応。

### 6. シナリオを実行して採点
```bash
# 例: シナリオ1（productCatalogFailure）を注入
pwsh scripts/run-scenario.ps1 -Scenario 1
```
注入後、`prompts/alert-template.md` の「ページ」を A（MCP あり）と B（MCP なし）に同じ文面で渡し、結果を `results/` に記録、`results/scorecard.md` に採点します。

## 実験プロトコル（要約）

1. 1 つの障害を feature flag で ON にする。
2. 症状が Splunk に現れるまで待つ（1〜2 分）。
3. **同一のアラート文**を A と B に渡す。
4. A は MCP で自律調査、B は推論のみ。根本原因・根拠・対処・確信度を出力させる。
5. `scenarios.md` の ground truth と突合し、正誤・所要時間・トークン/コストを採点。
6. うまくいった例も**外した例も正直に**記録する。

詳細は `prompts/oncall-system.md` と `scenarios/scenarios.md`。

## 結果（実走済み: demo v2.2.0 / realm jp0）

### ⭐ 目玉: 自律オンコール実走
症状を一切教えず「本番で異常、調べて」だけで、Claude が **自分で Splunk MCP ツールを7回選んで** 3往復の調査を行い、
**根本原因（product-catalog の GetProduct エンドポイント）を断定 → 派手な上流エラーを波及と切り分け → 同時発生の別障害(payment)を分離 → ノイズ除外 → 確信度を正直に校正**、まで完走した。
→ 全トランスクリプト（AIの思考＋叩いたツール＋最終結論）: **[`results/autonomous-incident/transcript.md`](./results/autonomous-incident/transcript.md)**

### 比較（参考）: ツールあり/なし
6シナリオで A(Claude+MCP) と B(素のClaude) を採点。詳細は [`results/scorecard.md`](./results/scorecard.md) と各 `results/scenario-0X/`。

| # | 障害 | A: Claude+MCP | B: 素のClaude |
|---|---|:--:|:--:|
| 1 | product-catalog 特定商品エラー | 2 | 2 |
| 2 | payment 決済失敗 | 2 | 2 |
| 3 | cartFailure | 未再現(不採点) | 〃 |
| 4 | ad GCポーズ | 2 | 2 |
| 5 | recommendation メモリリーク | 1 | 2 |
| 6 | Kafka コンシューマラグ | 2 | 2 |
| | **合計(/10)** | **9** | **10** |

**読み筋**: スコアは僅差だが、B(ツールなし)が強いのは OTel Demo を学習済みで暗記が効くから（自社の新規システムでは無力）。A は実データで波及と根本原因を切り分け、ノイズを除外し、確証の無い所は留保した（汎用的）。最重要は #5：メモリリークは APM に即出ず A は「断定不可・メモリ時系列を見よ」と正直に留保。→ 鍵は **AI の自律的なツール選択**（APMで足りなければメモリ/キュー metrics に自分で潜る）。

## ライセンス

[MIT](./LICENSE)
