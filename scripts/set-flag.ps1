<#
.SYNOPSIS
  OpenTelemetry Demo (v2.2.0) の feature flag を ON/OFF する（flagd の JSON を編集）。
  flagd はファイル変更をホットリロードする。

.EXAMPLE
  pwsh scripts/set-flag.ps1 -Name productCatalogFailure -Variant on
  pwsh scripts/set-flag.ps1 -Name paymentFailure -Variant 100%
  pwsh scripts/set-flag.ps1 -Name productCatalogFailure -Variant off
  pwsh scripts/set-flag.ps1 -Reset      # 全フラグを off に戻す

.NOTES
  - Variant はフラグごとに異なる（on/off、100%/.../off、1x/10x/... 等）。
    demo.flagd.json の variants を見て指定すること。
  - targeting を持つフラグ（例 productCatalogFailure）は then 枝も書き換える。
#>
param(
  [string]$Name,
  [string]$Variant = "on",
  [switch]$Reset
)
$ErrorActionPreference = "Stop"

# .env から OTEL_DEMO_DIR を読む（無ければ既定）
$demoDir = "./opentelemetry-demo"
if (Test-Path ".env") {
  $line = Get-Content ".env" | Where-Object { $_ -match "^\s*OTEL_DEMO_DIR\s*=" } | Select-Object -First 1
  if ($line) { $demoDir = ($line -split "=", 2)[1].Trim() }
}
$flagFile = Join-Path $demoDir "src/flagd/demo.flagd.json"
if (-not (Test-Path $flagFile)) { throw "flagd 設定が見つかりません: $flagFile （OTEL_DEMO_DIR を確認）" }

$json = Get-Content $flagFile -Raw | ConvertFrom-Json

function Set-One($flagObj, [string]$variant) {
  $flagObj.defaultVariant = $variant
  # targeting: { if: [cond, then, else] } の then(=index1) も合わせる
  if ($flagObj.PSObject.Properties.Name -contains "targeting" -and $flagObj.targeting.if) {
    $flagObj.targeting.if[1] = $variant
  }
}

if ($Reset) {
  Write-Host "全フラグを off に戻します..."
  foreach ($p in $json.flags.PSObject.Properties) { Set-One $p.Value "off" }
} else {
  if (-not $Name) { throw "-Name <flag> を指定してください（または -Reset）" }
  if (-not ($json.flags.PSObject.Properties.Name -contains $Name)) {
    throw "フラグ '$Name' が demo.flagd.json に見つかりません。"
  }
  Write-Host "  $Name -> $Variant"
  Set-One $json.flags.$Name $Variant
}

$json | ConvertTo-Json -Depth 100 | Set-Content $flagFile -Encoding UTF8
Write-Host "保存しました: $flagFile （flagd が数秒でリロード）"
