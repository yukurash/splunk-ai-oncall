<#
.SYNOPSIS
  1 シナリオの障害を注入し、計測の開始時刻と「ページ」文面を出力する補助。
  Claude(A/B) の実行自体は対話なので、このスクリプトは "段取り" 役。

.EXAMPLE
  pwsh scripts/run-scenario.ps1 -Scenario 2
  pwsh scripts/run-scenario.ps1 -Reset
#>
param([int]$Scenario, [switch]$Reset)
$ErrorActionPreference = "Stop"

# シナリオ番号 -> { flag 名, 有効化する variant }（scenarios.md と対応, demo v2.2.0）
$map = @{
  1 = @{ flag = "productCatalogFailure";     variant = "on"   }
  2 = @{ flag = "paymentFailure";            variant = "100%" }
  3 = @{ flag = "cartFailure";               variant = "on"   }
  4 = @{ flag = "adManualGc";                variant = "on"   }
  5 = @{ flag = "recommendationCacheFailure"; variant = "on"  }
  6 = @{ flag = "kafkaQueueProblems";        variant = "on"   }
}
$symptom = @{
  1 = "一部の商品ページでエラーが出る、という問い合わせ。該当商品はカートに入れられない"
  2 = "購入の最終確定で決済エラーになる、というクレームが複数"
  3 = "カートが表示されない／更新できない、という報告"
  4 = "サイト全体が時々もたつく。常にではなく、間欠的に遅い"
  5 = "おすすめ表示が時間が経つほど遅くなる。再起動直後は速い"
  6 = "注文は通るが、確認メール等の後続処理が遅れている様子"
}

if ($Reset) { & "$PSScriptRoot/set-flag.ps1" -Reset; Write-Host "リセット完了。"; return }
if (-not $map.ContainsKey($Scenario)) { throw "Scenario は 1..6 で指定してください。" }

$f = $map[$Scenario]
Write-Host "=== シナリオ $Scenario : $($f.flag) ($($f.variant)) ==="
& "$PSScriptRoot/set-flag.ps1" -Name $f.flag -Variant $f.variant

$start = Get-Date
Write-Host ""
Write-Host "注入時刻: $($start.ToString('yyyy-MM-dd HH:mm:ss')) JST"
Write-Host "症状が Splunk に出るまで 1〜2 分待ってから A/B に下記ページを渡してください。"
Write-Host ""
Write-Host "----- 渡すページ（A/B 共通） -----"
Write-Host "[PAGE] Astronomy Shop / 本番"
Write-Host "発生時刻: $($start.ToString('yyyy-MM-dd HH:mm')) JST"
Write-Host "重大度: SEV-2"
Write-Host "症状: $($symptom[$Scenario])"
Write-Host "依頼: 根本原因を特定し、推奨対処まで報告してください。"
Write-Host "---------------------------------"
Write-Host ""
Write-Host "結果は results/scenario-0$Scenario/ に保存し、scorecard.md / score.csv を更新。"
Write-Host "終わったら: pwsh scripts/run-scenario.ps1 -Reset"
