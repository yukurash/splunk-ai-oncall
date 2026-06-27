### APMサービス指標（窓:-3m〜now）
service | health | req | err | rootCauseErr | p50 | p90 | p99
---|---|---|---|---|---|---|---
flagd.evaluation.v2.Service | Critical | 17 | 5 | 5 | 4ms | 319677ms | 332766ms
payment | Critical | 3 | 1 | 1 | 8ms | 315570ms | 321575ms
load-generator | Ok | 162 | 0 | 0 | 2408ms | 3877ms | 98946ms
local-llm.com | Critical | 5 | 5 | 5 | 188ms | 208ms | 215ms
frontend-web | Ok | 2884 | 0 | 0 | 43ms | 117ms | 1516ms
product-reviews | Ok | 126 | 1 | 0 | 18ms | 45ms | 1740ms
frontend | Ok | 4787 | 5 | 5 | 4ms | 19ms | 48ms
frontend-proxy | Ok | 6859 | 7 | 2 | 4ms | 18ms | 3433ms
frontend-proxy:8080 | Ok | 1 | 0 | 0 | 18ms | 18ms | 18ms
email | Ok | 2 | 0 | 0 | 10ms | 17ms | 19ms
product-catalog | Ok | 1929 | 0 | 0 | 5ms | 16ms | 28ms
flagd:8016 | Ok | 11 | 0 | 0 | 4ms | 13ms | 17ms
recommendation | Ok | 329 | 1 | 0 | 5ms | 10ms | 19ms

### エラー/根本原因トレース: ほぼ無し（recommendation を含むエラー無し）
### スロートレース(>500ms)
- 3135ms 起点=frontend-proxy/POST services=[frontend-proxy]
- 2541ms 起点=load-generator/browser_change_currency services=[load-generator]
- 1001ms 起点=frontend-web/documentLoad services=[frontend-web]
- 3171ms 起点=frontend-proxy/POST services=[frontend-proxy]
- 3193ms 起点=frontend-proxy/POST services=[frontend-proxy]
