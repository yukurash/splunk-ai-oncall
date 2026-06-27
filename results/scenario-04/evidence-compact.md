### APMサービス指標（窓:-2m〜now / env:unknown）
service | health | req | err | rootCauseErr | p50 | p90 | p99
---|---|---|---|---|---|---|---
load-generator | Ok | 136 | 0 | 0 | 2294ms | 3767ms | 9303ms
ad | Ok | 55 | 0 | 0 | 689ms | 957ms | 1440ms
frontend-web | Ok | 1911 | 0 | 0 | 46ms | 150ms | 995ms
checkout | Ok | 28 | 0 | 0 | 1ms | 42ms | 85ms
product-reviews | Ok | 81 | 0 | 0 | 16ms | 27ms | 32ms
frontend | Ok | 3414 | 0 | 0 | 4ms | 21ms | 620ms
frontend-proxy | Ok | 4827 | 0 | 0 | 4ms | 19ms | 3452ms
product-catalog | Ok | 1439 | 0 | 0 | 5ms | 17ms | 38ms
email | Ok | 5 | 0 | 0 | 12ms | 15ms | 15ms
flagd:8016 | Ok | 5 | 0 | 0 | 2ms | 11ms | 12ms
recommendation | Ok | 245 | 0 | 0 | 5ms | 10ms | 20ms
shipping | Ok | 47 | 0 | 0 | 4ms | 6ms | 8ms
flagd.evaluation.v2.Service | Ok | 9 | 0 | 0 | 2ms | 5ms | 7ms
cart | Ok | 361 | 0 | 0 | 1ms | 4ms | 9ms

### スロートレース(>500ms)
- 3164ms 起点=load-generator/browser_add_to_cart services=[load-generator]
- 4094ms 起点=frontend-proxy/POST services=[frontend-proxy]
- 4397ms 起点=frontend-proxy/POST services=[frontend-proxy]
- 1192ms 起点=frontend-web/GET services=[frontend-web,ad,frontend,frontend-proxy]
- 3754ms 起点=load-generator/browser_add_to_cart services=[load-generator]

### エラートレース(err)
- 起点=load-generator/user_ask_product_ai_assistant
- 起点=load-generator/user_ask_product_ai_assistant