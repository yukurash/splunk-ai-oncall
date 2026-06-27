# RUNBOOK — 実験の回し方

> 環境（デモ→Splunk 疎通）は構築・検証済み（`results/setup-notes.md`）。
> ここでは **Claude に Splunk MCP で障害を自律調査させ、A/B を採点する**手順だけを示す。

## 前提
- デモが起動中（`docker compose -f compose.yaml -f ../docker-compose.splunk.yml ps` で healthy）。
- `.env` に realm / token / `SPLUNK_MCP_URL`(tyo10) が入っている。

## 0. なぜ「新しいセッション」が要るか
Claude Code は **起動時に MCP を読み込む**。`.mcp.json` を効かせるには、リポジトリ直下で env を
export してから **改めて `claude` を起動**する（実行中セッションに後付け不可）。

```bash
cd splunk-ai-oncall
set -a; . ./.env; set +a      # PowerShell は各 SPLUNK_* を $env: で設定
claude                        # ここで .mcp.json が読まれる
```
Claude 内で `/mcp`（または別シェルで `claude mcp list`）→ **splunk-o11y が connected** を確認。

## 1. 各シナリオ（1〜6）の手順
`scenarios/scenarios.md` の ground truth を見ながら、シナリオごとに：

```bash
pwsh scripts/run-scenario.ps1 -Reset          # まず全フラグ off
pwsh scripts/run-scenario.ps1 -Scenario N     # 障害を注入し「ページ」を出力
# → 症状が Splunk に出るまで 1〜2 分待つ
```

### B（素の Claude / ツールなし）を先に
先入観を避けるため B を先に取る。**MCP を使わせない**（splunk-o11y を切るか「ツールを使うな」と明示）。
`prompts/alert-template.md` のページ＋B用の一文を渡し、回答を `results/scenario-0N/transcript-B.md` に保存。

### A（Claude + Splunk MCP）
同じセッション（MCP 接続済み）で、`prompts/oncall-system.md` をシステム指示として与え、同じページを渡す。
Claude が `search_alerts_or_incidents` → `get_apm_service_dependencies` → `get_apm_exemplar_traces` などで
自律調査するのを観察。回答・使用ツール列・所要時間・トークン/コストを
`results/scenario-0N/transcript-A.md` に保存。Splunk のスクショ（トレース等）も保存（**トークンはマスク**）。

### 採点
`scenarios/scenarios.md` の正解と突合し、`scripts/score.csv` と `results/scorecard.md` を更新。
（正解=2 / 部分=1 / 不正解=0、＋時間・コスト）

```bash
pwsh scripts/run-scenario.ps1 -Reset          # 次へ行く前に必ず off
```

## 2. 全6シナリオ後
- `results/scorecard.md` を集計（正答数・時間・コスト）。
- `article/draft.md` の `[実データ]` を埋める（執筆方針：実体験ベース・簡潔・ビジュアル先行）。
- 面白かった誤診を必ず1つ拾う。

## 3. 後片付け
```bash
pwsh scripts/run-scenario.ps1 -Reset
cd opentelemetry-demo && docker compose -f compose.yaml -f ../docker-compose.splunk.yml down
```
検証が終わったら **Splunk のアクセストークンを再発行**（チャットに出たため）。

## メモ
- A と B は別文脈で。B に MCP を使わせない運用が肝。
- MCP の `npx mcp-remote` は初回に依存を取得する。Node.js 18+ が必要。
