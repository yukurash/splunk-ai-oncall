#!/usr/bin/env bash
# OpenTelemetry Demo (v2.2.0) の feature flag を ON/OFF する（flagd JSON を編集）。
#
# 使い方:
#   scripts/set-flag.sh productCatalogFailure on
#   scripts/set-flag.sh paymentFailure 100%
#   scripts/set-flag.sh productCatalogFailure off
#   scripts/set-flag.sh --reset           # 全フラグを off
#
# 依存: jq
# 注意: Variant はフラグごとに異なる（demo.flagd.json の variants を見る）。
#       targeting を持つフラグは then 枝も合わせて書き換える。
set -euo pipefail

DEMO_DIR="${OTEL_DEMO_DIR:-./opentelemetry-demo}"
if [ -f .env ]; then
  v="$(grep -E '^\s*OTEL_DEMO_DIR\s*=' .env | head -1 | cut -d= -f2- | xargs || true)"
  [ -n "$v" ] && DEMO_DIR="$v"
fi
FLAG_FILE="$DEMO_DIR/src/flagd/demo.flagd.json"
[ -f "$FLAG_FILE" ] || { echo "flagd 設定が見つかりません: $FLAG_FILE" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq が必要です" >&2; exit 1; }

tmp="$(mktemp)"
if [ "${1:-}" = "--reset" ]; then
  echo "全フラグを off に戻します..."
  jq '.flags |= map_values(.defaultVariant = "off"
        | if has("targeting") then .targeting.if[1] = "off" else . end)' \
    "$FLAG_FILE" > "$tmp"
else
  NAME="${1:?flag 名を指定してください}"
  VAR="${2:-on}"
  echo "  $NAME -> $VAR"
  jq --arg n "$NAME" --arg v "$VAR" \
    'if .flags[$n] then
        .flags[$n].defaultVariant = $v
        | if .flags[$n].targeting then .flags[$n].targeting.if[1] = $v else . end
      else error("flag not found: \($n)") end' \
    "$FLAG_FILE" > "$tmp"
fi
mv "$tmp" "$FLAG_FILE"
echo "保存しました: $FLAG_FILE （flagd が数秒でリロード）"
