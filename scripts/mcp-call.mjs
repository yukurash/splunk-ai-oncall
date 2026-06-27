#!/usr/bin/env node
// Splunk Observability MCP gateway を CLI から叩く最小クライアント。
// Claude Code を介さず、curl 相当で tools/call を実行する（検証・自動化用）。
//
// 使い方:
//   node scripts/mcp-call.mjs <tool_name> '<arguments-json>'
//   node scripts/mcp-call.mjs --list                 # tools 一覧
//
// 必要な環境変数: SPLUNK_MCP_URL, SPLUNK_ACCESS_TOKEN, SPLUNK_REALM
//   例: set -a; . ./.env; set +a; node scripts/mcp-call.mjs o11y_get_apm_environments '{"params":{"time_range":{"start":"-40m","stop":"now"}}}'

const URL = process.env.SPLUNK_MCP_URL;
const TOKEN = process.env.SPLUNK_ACCESS_TOKEN;
const REALM = process.env.SPLUNK_REALM;
if (!URL || !TOKEN || !REALM) { console.error("env が未設定 (SPLUNK_MCP_URL/SPLUNK_ACCESS_TOKEN/SPLUNK_REALM)"); process.exit(2); }

const headers = {
  "Content-Type": "application/json",
  "Accept": "application/json, text/event-stream",
  "X-SF-TOKEN": TOKEN,
  "X-SF-REALM": REALM,
};

function parseSSE(text) {
  // "event: message\ndata: {json}\n\n" から最後の data 行の JSON を返す
  const lines = text.split("\n").filter(l => l.startsWith("data: "));
  if (!lines.length) throw new Error("no SSE data in response: " + text.slice(0, 300));
  return JSON.parse(lines[lines.length - 1].slice(6));
}

async function rpc(method, params) {
  const res = await fetch(URL, {
    method: "POST", headers,
    body: JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method, params }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${text.slice(0, 300)}`);
  return parseSSE(text);
}

const arg = process.argv[2];
if (!arg) { console.error("tool 名 (または --list) を指定"); process.exit(2); }

if (arg === "--list") {
  const r = await rpc("tools/list", {});
  for (const t of r.result.tools) console.log(t.name);
  process.exit(0);
}

const toolArgs = process.argv[3] ? JSON.parse(process.argv[3]) : {};
const r = await rpc("tools/call", { name: arg, arguments: toolArgs });
if (r.error) { console.error("MCP error:", JSON.stringify(r.error)); process.exit(1); }
// result.content[] の text を連結して出力
const out = (r.result?.content || []).map(c => c.text ?? JSON.stringify(c)).join("\n");
console.log(out || JSON.stringify(r.result, null, 2));
