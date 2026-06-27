<#
.SYNOPSIS
  1 シナリオの障害を注入し、計測の開始時刻と「ページ」文面を出力する補助スクリプト。
  Claude(A/B) の実行自体は対話なので、このスクリプトは "段取り" を整える役割。

.EXAMPLE
  pwsh scripts/run-scenario.ps1 -Scenario 1
  pwsh scripts/run-scenario.ps1 -Reset
#>
param(
  [int]$Scenario,
  [switch]$Reset
)
$ErrorActionPreference = "Stop"

# シナリオ番号 -> flag 名（scenarios.md と対応。バージョンで要確認）
$flags = @{
  1 = "productCatalogFailure"
  2 = "paymentServiceFailure"
  3 = "cartServiceFailure"
  4 = "adServiceManualGc"
  5 = "recommendationServiceCacheFailure"
  6 = "kafkaQueueProblems"
}

if ($Reset) {
  & "$PSScriptRoot/set-flag.ps1" -Reset
  Write-Host "リセット完了。"
  return
}

if (-not $flags.ContainsKey($Scenario)) { throw "Scenario は 1..6 で指定してください。" }
$flag = $flags[$Scenario]

Write-Host "=== シナリオ $Scenario : $flag ==="
& "$PSScriptRoot/set-flag.ps1" -Name $flag -State on

$start = Get-Date
Write-Host ""
Write-Host "注入時刻: $($start.ToString('yyyy-MM-dd HH:mm:ss')) JST"
Write-Host "症状が Splunk に出るまで 1〜2 分待ってから A/B に下記ページを渡してください。"
Write-Host ""
Write-Host "----- 渡すページ（A/B 共通） -----"
Write-Host "[PAGE] Astronomy Shop / 本番"
Write-Host "発生時刻: $($start.ToString('yyyy-MM-dd HH:mm')) JST"
Write-Host "重大度: SEV-2"
Write-Host "症状: （scenarios.md のシナリオ $Scenario の症状を貼る）"
Write-Host "依頼: 根本原因を特定し、推奨対処まで報告してください。"
Write-Host "---------------------------------"
Write-Host ""
Write-Host "結果は results/scenario-0$Scenario/ に保存し、scorecard.md / score.csv を更新。"
Write-Host "終わったら: pwsh scripts/run-scenario.ps1 -Reset"
