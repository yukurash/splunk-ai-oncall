#!/usr/bin/env node
// OpenTelemetry Demo の feature flag を ON/OFF する（flagd JSON を編集）。
// jq/pwsh 不要のクロスプラットフォーム版。flagd は再起動で確実に反映（Windows の
// bind mount ではファイル監視が効かないことがあるため、呼び出し側で docker restart flagd 推奨）。
//
//   node scripts/set-flag.mjs <flagName> <variant>
//   node scripts/set-flag.mjs --reset
import { readFileSync, writeFileSync } from "node:fs";

const demoDir = process.env.OTEL_DEMO_DIR || "./opentelemetry-demo";
const file = `${demoDir}/src/flagd/demo.flagd.json`;
const j = JSON.parse(readFileSync(file, "utf8"));

function setOne(f, variant) {
  f.defaultVariant = variant;
  if (f.targeting && Array.isArray(f.targeting.if)) f.targeting.if[1] = variant; // then 枝
}

const [, , a, b] = process.argv;
if (a === "--reset") {
  for (const f of Object.values(j.flags)) setOne(f, "off");
  console.log("all flags -> off");
} else {
  if (!a) { console.error("usage: set-flag.mjs <flag> <variant> | --reset"); process.exit(2); }
  if (!j.flags[a]) { console.error(`flag not found: ${a}`); process.exit(1); }
  setOne(j.flags[a], b || "on");
  console.log(`${a} -> ${b || "on"}`);
}
writeFileSync(file, JSON.stringify(j, null, 2));
