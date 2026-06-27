# 環境構築ログ（一次情報）— 2026-06-27

実際に動かして確認した事実とハマり。記事の「環境構築」「ハマり所」セクションの素材。

## 確定した構成
- OpenTelemetry Demo **v2.2.0**（compose は `compose.yaml`、19コンテナ）
- OTel Collector: **contrib 0.151.0**（demo 同梱、サービス名 `otel-collector`、mem 200M）
- flagd **v0.14.2**（障害注入は `src/flagd/demo.flagd.json`）
- Splunk Observability Cloud realm **jp0**（Tokyo / MCP region `tyo10`）
- バックエンドは Splunk のみ（ローカル Jaeger/Prometheus/OpenSearch は起動せず＝軽量）

## 疎通確認（Splunk 側 API で確認済み）
- `GET /v2/dimension?query=sf_service:*` → **count 18**（デモの各サービスが APM に登録）
- `GET /v2/metric?query=sf_metric:*request*` → **38 件**（APM のリクエスト系メトリクス）
- アクセストークンは **API 読み取り可**（不正クエリで 400 が返る＝認証は通過。401/403 ではない）→ MCP でも使える見込み

## ハマり（記事ネタ）
1. **`sapm` exporter が消えていた**: contrib 0.151.0 では `sapm` は削除済みで、`unknown type "sapm"` で collector がクラッシュループ。
   → トレースは **OTLP/HTTP** で送る。`otlphttp` exporter の `traces_endpoint: https://ingest.jp0.signalfx.com/v2/trace/otlp` ＋ ヘッダ `X-SF-Token`。
   （`otlphttp` は将来 `otlp_http` への改名が推奨される deprecation 警告あり。動作はする）
2. **ログ送信が 404**: `splunk_hec` を `https://ingest.jp0.signalfx.com/v1/log` に向けると 404。O11y の Log Observer 取込は別経路。
   → 今回の AI 調査は APM＋メトリクス＋アラートで完結しログ不要なので、**ログ送信は無効化**してノイズを消した。
3. **Collector の config マージは配列を“置換”**: extras の pipeline で base の exporter（traces=[debug, span_metrics]）を書き忘れると消える。`exporters: [debug, span_metrics, otlphttp/splunk]` のように repeat する。
4. **flag の有効化は単純な on/off ではない**: `paymentFailure` は `100%` 等のパーセント変種、`productCatalogFailure` は targeting（特定商品 OLJCESPC7Z のみ）。`scripts/set-flag.ps1` が targeting の then 枝も書き換えるよう実装。

## MCP ゲートウェイ疎通（curl で実証済み）
- `POST https://region-tyo10.api.scs.splunk.com/system/mcp-gateway/v1/`（ヘッダ `X-SF-TOKEN`/`X-SF-REALM`）
  → `initialize` が HTTP 200、`Unified MCP Gateway v3.0.2` 応答。`tools/list` も 200。
- 実ツール名（12個）: `o11y_get_apm_services` / `o11y_get_apm_service_dependencies` /
  `o11y_get_apm_service_errors_and_requests` / `o11y_get_apm_service_latency` /
  `o11y_get_apm_exemplar_traces` / `o11y_get_apm_trace_tool` / `o11y_search_alerts_or_incidents` /
  `o11y_get_metric_names` / `o11y_get_metric_metadata` / `o11y_generate_signalflow_program` /
  `o11y_execute_signalflow_program` / `o11y_get_apm_environments`
- セッションIDは不要（ステートレスに応答）。→ `prompts/oncall-system.md` を実ツール名に更新済み。

## まだやってないこと（本番実行）
- 6シナリオの A/B 実走・採点・記事の実データ埋め（→ `RUNBOOK.md`）。
  ※ Claude が MCP を使うので、リポジトリ直下で env export して起動した**別の Claude Code セッション**で行う。
