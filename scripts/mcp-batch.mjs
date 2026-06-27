#!/usr/bin/env node
// 自律SREサブエージェントが出した `CALL <tool> <json>` 行をまとめて Splunk MCP に投げ、
// 結果を圧縮して返す中継ヘルパー。
//
//   set -a; . ./.env; set +a
//   node scripts/mcp-batch.mjs <calls.txt>
//
// calls.txt の各行: CALL o11y_get_apm_services {"params":{...}}

import { readFileSync } from "node:fs";
const URL = process.env.SPLUNK_MCP_URL, TOKEN = process.env.SPLUNK_ACCESS_TOKEN, REALM = process.env.SPLUNK_REALM;
const headers = { "Content-Type": "application/json", "Accept": "application/json, text/event-stream", "X-SF-TOKEN": TOKEN, "X-SF-REALM": REALM };

async function call(name, args) {
  const res = await fetch(URL, { method: "POST", headers, body: JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method: "tools/call", params: { name, arguments: args } }) });
  const text = await res.text();
  const line = text.split("\n").filter(l => l.startsWith("data: ")).pop();
  if (!line) return { _raw: text.slice(0, 200) };
  const d = JSON.parse(line.slice(6));
  if (d.error) return { _error: d.error };
  const t = (d.result?.content || []).map(c => c.text ?? "").join("\n");
  try { return JSON.parse(t); } catch { return t; }
}

// link/url を除去・長文切詰め・配列制限
function prune(x, d = 0) {
  if (Array.isArray(x)) return x.slice(0, 20).map(v => prune(v, d + 1));
  if (x && typeof x === "object") {
    const o = {};
    for (const [k, v] of Object.entries(x)) { if (/link|url|trace_analyzer/i.test(k)) continue; o[k] = prune(v, d + 1); }
    return o;
  }
  if (typeof x === "string" && x.length > 300) return x.slice(0, 300) + "…";
  return x;
}

// サービス一覧は要点だけに圧縮
function compact(name, r) {
  if (name === "o11y_get_apm_services" && r && Array.isArray(r.services)) {
    return { services: r.services.map(it => ({
      name: it.service?.name, health: it.health,
      req: it.requestCount?.value, err: it.errorCount?.value, rootCauseErr: it.rootCauseErrorCount?.value,
      p50us: it.requestDurationMicrosP50?.value, p90us: it.requestDurationMicrosP90?.value, p99us: it.requestDurationMicrosP99?.value,
    })) };
  }
  if (/exemplar_traces/.test(name) && r && Array.isArray(r.items)) {
    return { totalItems: r.items.length, items: r.items.slice(0, 8).map(x => {
      const it = x.item || x; const rc = [];
      for (const sc of (it.serviceSpanCounts || [])) for (const e of (sc.errors || [])) if (e.isRootCause) rc.push(sc.service);
      return { trace: String(it.traceId).slice(0, 12), initiating: `${it.initiatingService}/${it.initiatingOperation}`, durMs: Math.round((it.durationMicros || 0) / 1000), rootCause: [...new Set(rc)], services: (it.serviceSpanCounts || []).map(s => s.service) };
    }) };
  }
  return prune(r);
}

const file = process.argv[2];
const lines = readFileSync(file, "utf8").split("\n").map(l => l.trim()).filter(l => l.startsWith("CALL "));
if (!lines.length) { console.log("(CALL 行がありません)"); process.exit(0); }

for (const line of lines) {
  const m = line.match(/^CALL\s+(\S+)\s+(\{.*\})\s*$/s);
  if (!m) { console.log(`--- 解析失敗: ${line.slice(0, 80)}`); continue; }
  const [, tool, argStr] = m;
  let args; try { args = JSON.parse(argStr); } catch (e) { console.log(`--- ${tool}: JSON引数エラー ${e.message}`); continue; }
  try {
    const r = await call(tool, args);
    console.log(`\n=== RESULT ${tool} ===`);
    console.log(JSON.stringify(compact(tool, r)).slice(0, 2600));
  } catch (e) { console.log(`=== ERROR ${tool}: ${String(e).slice(0, 200)}`); }
}
