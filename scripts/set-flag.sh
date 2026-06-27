#!/usr/bin/env bash
# OpenTelemetry Demo の feature flag を ON/OFF する（flagd の JSON を編集）。
#
# 使い方:
#   scripts/set-flag.sh productCatalogFailure on
#   scripts/set-flag.sh productCatalogFailure off
#   scripts/set-flag.sh --reset           # 全フラグを off
#
# 依存: jq
# 注意: flagd の構造は demo のバージョンで変わる。効かない時は
#       src/flagd/demo.flagd.json を直接確認すること。
set -euo pipefail

DEMO_DIR="${OTEL_DEMO_DIR:-./opentelemetry-demo}"
if [ -f .env ]; then
  # shellcheck disable=SC2046
  DEMO_DIR="$(grep -E '^\s*OTEL_DEMO_DIR\s*=' .env | head -1 | cut -d= -f2- | xargs || echo "$DEMO_DIR")"
fi
FLAG_FILE="$DEMO_DIR/src/flagd/demo.flagd.json"

[ -f "$FLAG_FILE" ] || { echo "flagd 設定が見つかりません: $FLAG_FILE" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq が必要です" >&2; exit 1; }

tmp="$(mktemp)"
if [ "${1:-}" = "--reset" ]; then
  echo "全フラグを off に戻します..."
  jq '.flags |= map_values(if has("defaultVariant") then .defaultVariant = "off" else . end)' \
    "$FLAG_FILE" > "$tmp"
else
  NAME="${1:?-flag 名を指定してください}"
  STATE="${2:-on}"
  echo "  $NAME -> $STATE"
  jq --arg n "$NAME" --arg s "$STATE" \
    'if .flags[$n] then .flags[$n].defaultVariant = $s else error("flag not found: \($n)") end' \
    "$FLAG_FILE" > "$tmp"
fi
mv "$tmp" "$FLAG_FILE"
echo "保存しました: $FLAG_FILE （flagd が数秒でリロードします）"
