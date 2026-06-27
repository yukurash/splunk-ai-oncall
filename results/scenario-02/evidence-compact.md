### APMサービス指標（窓:-4m〜now）
service | health | req | err | rootCauseErr | p99
---|---|---|---|---|---
flagd.evaluation.v2.Service | Critical | 19 | 5 | 5 | 463314ms
frontend | Ok | 5677 | 5 | 2 | 50ms
frontend-proxy | Ok | 7995 | 5 | 0 | 3443ms
payment | Critical | 6 | 4 | 4 | 449915ms
checkout | Warning | 52 | 3 | 0 | 41ms
local-llm.com | Critical | 2 | 2 | 2 | 198ms
ad | Ok | 127 | 1 | 0 | 2865ms
cart | Ok | 558 | 1 | 0 | 9ms
product-reviews | Ok | 136 | 1 | 0 | 910ms
recommendation | Ok | 396 | 1 | 0 | 19ms
currency | Ok | 467 | 0 | 0 | 1ms
email | Ok | 2 | 0 | 0 | 8ms

### 根本原因エラートレース(rc_err)
- 起点=load-generator/user_checkout_multi rootCause=[payment]
- 起点=load-generator/user_checkout_multi rootCause=[payment]
- 起点=load-generator/user_checkout_single rootCause=[payment]
- 起点=load-generator/user_checkout_single rootCause=[payment]
