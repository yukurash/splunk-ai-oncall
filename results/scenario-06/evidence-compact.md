### APMサービス指標（窓:-3m〜now / 主要のみ）
service | health | req | err | rootCauseErr | p99
---|---|---|---|---|---
checkout | Ok | 36 | 0 | 0 | 30ms
email | Ok | 1 | 0 | 0 | 4ms
payment | Critical | 2 | 1 | 1 | 446223ms
shipping | Ok | 43 | 0 | 0 | 13ms
frontend | Ok | 3979 | 4 | 4 | 49ms
frontend-proxy | Ok | 5505 | 5 | 1 | 3459ms
cart | Ok | 386 | 1 | 0 | 9ms
recommendation | Ok | 277 | 1 | 0 | 23ms
product-catalog | Ok | 1619 | 0 | 0 | 511ms

注: APMサービス一覧に kafka / accounting / fraud-detection（非同期コンシューマ）は出ていない。checkout は health=Ok・p99=30ms で正常。エラー/スロートレースに後続処理の遅延は表れていない。
