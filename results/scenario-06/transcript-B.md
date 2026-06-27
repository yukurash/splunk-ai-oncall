# シナリオ6 / Responder B（素の Claude・ツールなし）

入力＝アラート文のみ。subagent_tokens: 15600 / tool_uses: 0 / ~34s

---

## 根本原因（断定）
Kafka の注文イベントトピックで**コンシューマラグが急増**。checkout は producer なので即成功・正常応答するが、後段の accounting / fraud-detection / email の consumer が消費に追いつかず、未処理メッセージが滞留して後続処理が遅延。

## 根拠（推論）
- 「チェックアウト成功・画面正常・フロントにエラーなし」なのに「後続処理だけ遅延」という非対称＝同期パスと非同期（Kafka）パスの分離を示す。
- checkout が注文イベントを Kafka に publish、accounting/fraud-detection/email が subscribe。producer 健全でも consumer が詰まれば「確定だけ速く、記帳・メールが遅い」状態に。
- 「大きく遅れている（落ちてはいない）」＝メッセージ消失ではなくラグ蓄積。
- OTel Demo の `kafkaQueueProblems` フラグがこの状況を再現する。

## 推奨対処
1. 対象トピックの consumer group lag を確認（kafka-consumer-groups --describe）。
2. 各 consumer の処理レイテンシ・エラー・リバランス履歴を確認。
3. ボトルネック consumer を水平スケール、パーティション増、毒メッセージは DLQ。
4. `kafkaQueueProblems` 等の負荷注入フラグを確認し ON なら OFF。

## 確信度（中〜高）
構成（checkout=producer、後続=consumer）と「同期成功・非同期のみ遅延」の一致度が高くカテゴリは断定可。ただしラグの一次要因（遅いconsumer/リバランス/パーティション不足/フラグ）はアラートだけでは特定しきれず中。
