#!/usr/bin/env node
// シナリオ実行時の "証拠パック" を Splunk MCP から収集する（回答者AIに渡す中立データ）。
// シナリオ非依存の固定プロトコルで取得 = 私(オペレータ)のバイアスを排除する。
//
// 使い方:
//   set -a; . ./.env; set +a
//   node scripts/gather-evidence.mjs <outDir> [startWindow]
//   例: node scripts/gather-evidence.mjs results/scenario-01 -20m
//
// 出力: <outDir>/evidence.json （リンク類を除去し文字列を切り詰めた compact 版）

import { writeFileSync, mkdirSync } from "node:fs";

const URL = process.env.SPLUNK_MCP_URL, TOKEN = process.env.SPLUNK_ACCESS_TOKEN, REALM = process.env.SPLUNK_REALM;
const ENV = "unknown";                       // demo は deployment.environment 未設定
const outDir = process.argv[2] || "results/_adhoc";
const start = process.argv[3] || "-20m";
const time_range = { start, stop: "now" };
const headers = { "Content-Type": "application/json", "Accept": "application/json, text/event-stream", "X-SF-TOKEN": TOKEN, "X-SF-REALM": REALM };

async function call(name, params) {
  const res = await fetch(URL, { method: "POST", headers, body: JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method: "tools/call", params: { name, arguments: { params } } }) });
  const text = await res.text();
  const line = text.split("\n").filter(l => l.startsWith("data: ")).pop();
  const d = JSON.parse(line.slice(6));
  if (d.error) throw new Error(name + ": " + JSON.stringify(d.error));
  const txt = (d.result?.content || []).map(c => c.text ?? "").join("\n");
  try { return JSON.parse(txt); } catch { return txt; }
}

// リンク/URL を除去し、長い文字列を切り詰める再帰プルーナ
function prune(x, depth = 0) {
  if (Array.isArray(x)) return x.slice(0, 25).map(v => prune(v, depth + 1));
  if (x && typeof x === "object") {
    const o = {};
    for (const [k, v] of Object.entries(x)) {
      if (/link|url|trace_analyzer/i.test(k)) continue;
      o[k] = prune(v, depth + 1);
    }
    return o;
  }
  if (typeof x === "string" && x.length > 400) return x.slice(0, 400) + "…";
  return x;
}

// flagd の EventStream（600秒の常時接続 gRPC ストリーム）はノイズなので除外する
function cleanTraces(obj) {
  if (obj && Array.isArray(obj.items)) {
    obj.items = obj.items.filter(x => {
      const it = x.item || x;
      const op = String(it.initiatingOperation || "");
      const svc = String(it.initiatingService || "");
      if (/flagd\.evaluation/i.test(op)) return false;
      if ((it.durationMicros || 0) > 60_000_000) return false; // 60s 超は常時接続
      if (/^local-llm/i.test(svc)) return false;
      return true;
    });
    obj.totalItems = obj.items.length;
  }
  return obj;
}

const evidence = { collected_at: new Date().toISOString(), environment: ENV, time_range };

// 1) サービス概要（全サービスの req/err/rootCauseErr/latency）
try {
  const s = await call("o11y_get_apm_services", { environment_name: ENV, time_range, order_by: "errorCount", include_entity_health: true });
  evidence.services = prune((s.services || []).map(it => ({
    name: it.service?.name, health: it.health,
    requestCount: it.requestCount?.value, errorCount: it.errorCount?.value,
    rootCauseErrorCount: it.rootCauseErrorCount?.value,
    p50us: it.requestDurationMicrosP50?.value, p90us: it.requestDurationMicrosP90?.value, p99us: it.requestDurationMicrosP99?.value,
  })));
} catch (e) { evidence.services_error = String(e); }

// 2) 根本原因エラートレース（環境横断）
try { evidence.root_cause_error_traces = prune(cleanTraces(await call("o11y_get_apm_exemplar_traces", { environment_name: ENV, exemplar_type: "rc_err", time_range }))); }
catch (e) { evidence.rc_err_error = String(e); }

// 3) エラートレース（環境横断）
try { evidence.error_traces = prune(cleanTraces(await call("o11y_get_apm_exemplar_traces", { environment_name: ENV, exemplar_type: "err", time_range }))); }
catch (e) { evidence.err_error = String(e); }

// 4) スロートレース（500ms 超）
try { evidence.slow_traces = prune(cleanTraces(await call("o11y_get_apm_exemplar_traces", { environment_name: ENV, exemplar_type: "lat_buck_", time_range, min_latency_micros: 500000 }))); }
catch (e) { evidence.slow_error = String(e); }

mkdirSync(outDir, { recursive: true });
const path = `${outDir}/evidence.json`;
writeFileSync(path, JSON.stringify(evidence, null, 1));
const svc = (evidence.services || []).filter(s => (s.errorCount > 20) || (s.p99us > 200000));
console.log("wrote", path);
console.log("suspect services (err>20 or p99>200ms):", svc.map(s => `${s.name}(err=${s.errorCount},p99=${Math.round((s.p99us||0)/1000)}ms)`).join(", ") || "(none obvious)");
