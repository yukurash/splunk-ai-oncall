### APMサービス指標（収集: 2026-06-27T04:58:22.255Z / 窓:-5m〜now / env:unknown）
service | health | req | err | rootCauseErr | p99
---|---|---|---|---|---
frontend-proxy | Ok | 9245 | 233 | 1 | 3509ms
frontend | Ok | 6770 | 232 | 3 | 48ms
product-catalog | Warning | 3073 | 229 | 229 | 46ms
frontend-web | Warning | 3587 | 204 | 0 | 1366ms
flagd.evaluation.v2.Service | Warning | 22 | 4 | 4 | 318237ms
local-llm.com | Critical | 3 | 3 | 3 | 779ms
ad | Ok | 193 | 1 | 0 | 22ms
checkout | Ok | 61 | 1 | 1 | 52ms
payment | Critical | 2 | 1 | 1 | 196565ms
product-reviews | Ok | 171 | 1 | 0 | 1290ms
recommendation | Ok | 531 | 1 | 0 | 20ms
cart | Ok | 659 | 0 | 0 | 9ms
currency | Ok | 591 | 0 | 0 | 1ms
email | Ok | 1 | 0 | 0 | 10ms

### 根本原因エラートレース(rc_err) (5件)
- trace c0b8d0a27a07 起点=frontend-web/GET dur=41ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace 19d08d61c34a 起点=frontend-web/GET dur=45ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace 6d44de7858dd 起点=frontend-web/GET dur=36ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,product-catalog,postgresql,frontend-proxy,recommendation,currency,frontend]
- trace c5ab201eb273 起点=frontend-proxy/GET dur=21ms rootCause=[product-catalog:ROOT_ERROR, frontend-proxy:ROOT_ERROR] services=[recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace e3bc89c008d8 起点=frontend-proxy/GET dur=26ms rootCause=[product-catalog:ROOT_ERROR] services=[recommendation,product-catalog,postgresql,frontend,frontend-proxy]

### エラートレース(err) (5件)
- trace cb2fee6b8f1a 起点=frontend-web/GET dur=45ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace c0b8d0a27a07 起点=frontend-web/GET dur=41ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace 19d08d61c34a 起点=frontend-web/GET dur=45ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,recommendation,product-catalog,postgresql,frontend,frontend-proxy]
- trace 6d44de7858dd 起点=frontend-web/GET dur=36ms rootCause=[product-catalog:ROOT_ERROR] services=[frontend-web,product-catalog,postgresql,frontend-proxy,recommendation,currency,frontend]
- trace c5ab201eb273 起点=frontend-proxy/GET dur=21ms rootCause=[product-catalog:ROOT_ERROR, frontend-proxy:ROOT_ERROR] services=[recommendation,product-catalog,postgresql,frontend,frontend-proxy]

### スロートレース(>500ms) (5件)
- trace 04925caf0a1a 起点=load-generator/browser_add_to_cart dur=3078ms rootCause=[-] services=[load-generator]
- trace 611466a5f252 起点=frontend-proxy/POST dur=3708ms rootCause=[-] services=[frontend-proxy]
- trace 88a3c939773f 起点=load-generator/browser_add_to_cart dur=3080ms rootCause=[-] services=[load-generator]
- trace 69e50af27e60 起点=frontend-proxy/POST dur=3664ms rootCause=[-] services=[frontend-proxy]
- trace 3b67e92c74f5 起点=frontend-proxy/POST dur=3265ms rootCause=[-] services=[frontend-proxy]
