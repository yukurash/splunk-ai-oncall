<#
.SYNOPSIS
  OpenTelemetry Demo の feature flag を ON/OFF する（flagd の JSON を編集）。

.EXAMPLE
  pwsh scripts/set-flag.ps1 -Name productCatalogFailure -State on
  pwsh scripts/set-flag.ps1 -Name productCatalogFailure -State off
  pwsh scripts/set-flag.ps1 -Reset      # 全フラグを off に戻す

.NOTES
  flagd はファイル変更をホットリロードする。demo のバージョンによって
  defaultVariant 以外の構造（state/variants）の場合があるので、効かない時は
  src/flagd/demo.flagd.json を直接見て合わせること。
#>
param(
  [string]$Name,
  [ValidateSet("on", "off")] [string]$State = "on",
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
if (-not (Test-Path $flagFile)) {
  throw "flagd 設定が見つかりません: $flagFile （OTEL_DEMO_DIR を確認）"
}

$json = Get-Content $flagFile -Raw | ConvertFrom-Json

function Set-Flag([object]$flags, [string]$flagName, [string]$variant) {
  if (-not $flags.PSObject.Properties.Name.Contains($flagName)) {
    throw "フラグ '$flagName' が見つかりません。demo.flagd.json を確認してください。"
  }
  $flags.$flagName.defaultVariant = $variant
  Write-Host "  $flagName -> $variant"
}

if ($Reset) {
  Write-Host "全フラグを off に戻します..."
  foreach ($p in $json.flags.PSObject.Properties) {
    if ($p.Value.PSObject.Properties.Name -contains "defaultVariant") {
      $p.Value.defaultVariant = "off"
    }
  }
} else {
  if (-not $Name) { throw "-Name <flagName> を指定してください（または -Reset）" }
  Write-Host "フラグを設定します:"
  Set-Flag $json.flags $Name $State
}

$json | ConvertTo-Json -Depth 100 | Set-Content $flagFile -Encoding UTF8
Write-Host "保存しました: $flagFile （flagd が数秒でリロードします）"
