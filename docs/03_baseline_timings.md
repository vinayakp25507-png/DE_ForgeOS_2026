# CP2 – Baseline Query Performance Report

## 1. Benchmark methodology

- Database: PostgreSQL `whatsapp` on the local PostgreSQL instance.
- Dataset: the validated WhatsApp seed dataset (877,738 records across nine tables).
- Measurement: `EXPLAIN (ANALYZE, BUFFERS)`.
- Each query was executed three times.
- Average execution time is calculated from the three recorded execution times.
- Write queries W01–W05 were executed inside transactions followed by ROLLBACK.
- Full execution plans for all three runs are retained as individual `.txt` files.

## 2. Baseline timing results

| Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: Chats screen: latest message in each active chat of user 965 | READ | 24.013 | 18.451 | 16.345 | 19.603 |
| R02: Latest 50 messages in group 22556 | READ | 4.210 | 3.433 | 3.127 | 3.590 |
| R03: Unread message counts per chat for user 965 | READ | 19.425 | 9.060 | 8.302 | 12.262 |
| R04: Search for meeting in chats belonging to user 965 | READ | 19.245 | 19.145 | 17.964 | 18.785 |
| R05: Registration phone number lookup | READ | 0.314 | 0.029 | 0.024 | 0.122 |
| R06: Last-seen information for direct chat contacts | READ | 4.313 | 2.733 | 2.578 | 3.208 |
| R07: Current members and roles in group 22556 | READ | 3.846 | 0.138 | 0.119 | 1.368 |
| R08: Undelivered receipts before the June 30 cutoff | READ | 14.595 | 14.455 | 14.230 | 14.427 |
| R09: Top 20 users by uploaded media storage | READ | 9.432 | 10.705 | 10.628 | 10.255 |
| R10: Daily active senders during June 2026 | READ | 8.148 | 8.093 | 8.136 | 8.126 |
| R11: Missed calls received by user 965 since January 2025 | READ | 5.209 | 5.695 | 5.962 | 5.622 |
| R12: Users forwarding at least two messages on the same day | READ | 5.899 | 5.951 | 6.854 | 6.235 |
| R13: Unanswered questions in group 20501 | READ | 24.504 | 23.101 | 22.887 | 23.497 |
| R14: Top 10 groups by distinct senders during June 2026 | READ | 8.374 | 6.541 | 51.065 | 21.993 |
| R15: Block status between users 3064 and 17793 | READ | 0.029 | 0.027 | 0.053 | 0.036 |
| R16: Read receipts for message 119989 | READ | 1.178 | 0.079 | 0.068 | 0.442 |
| R17: Average send-to-read time by message type | READ | 17.197 | 16.204 | 18.363 | 17.255 |
| R18: Inactive users still participating in groups | READ | 16.266 | 16.725 | 15.892 | 16.294 |
| R19: Group health: latest message and June message count | READ | 20049.866 | 19732.215 | 17708.361 | 19163.481 |
| R20: Message volume by hour and message type | READ | 49.854 | 47.546 | 48.048 | 48.483 |
| R21: Edited and deleted message percentages by type | READ | 14.776 | 29.353 | 13.482 | 19.204 |
| R22: Message history page 4001 using OFFSET | READ | 22.551 | 9.007 | 9.863 | 13.807 |
| R23: Inactive WEB and DESKTOP devices | READ | 4.460 | 3.730 | 4.363 | 4.184 |
| R24: Duplicate media identified by SHA-256 | READ | 8.227 | 9.577 | 7.887 | 8.564 |
| R25: Recursive reply chain starting at message 119989 | READ | 0.199 | 0.131 | 0.064 | 0.131 |
| W01: Insert a text message into group 22556 | WRITE | 2.091 | 0.447 | 0.444 | 0.994 |
| W02: Mark unread receipts as read for user 965 | WRITE | 9.634 | 3.013 | 3.115 | 5.254 |
| W03: Delete message 119989 | WRITE | 0.139 | 0.108 | 0.112 | 0.120 |
| W04: Insert 5000 message delivery receipts | WRITE | 25.531 | 25.565 | 25.769 | 25.622 |
| W05: User 965 leaves group 20898 | WRITE | 0.381 | 0.131 | 0.131 | 0.214 |

## 3. Scan types and performance observations

| Query | Scan type recorded in the benchmark | Explanation |
|---|---|---|
| R01 | Seq Scan on chat_members | Index Scan using chats_pkey on chats | Seq Scan on messages | Sequential membership/message scans and a per-chat latest-message lookup increase work. |
| R02 | Seq Scan on messages | The message table is scanned and the chat filter plus descending timestamp ordering require work. |
| R03 | Seq Scan on message_receipts | Index Scan using messages_pkey on messages | Receipts are scanned and joined to messages before grouping by chat. |
| R04 | Seq Scan on messages | Seq Scan on chat_members | Leading-wildcard ILIKE cannot use an ordinary B-tree lookup; both messages and memberships are scanned. |
| R05 | Index Scan using users_phone_e164_key on users | The unique phone-number index supports a selective lookup. |
| R06 | Seq Scan on chat_members | Index Only Scan using chat_members_pkey on chat_members | Index Scan using chats_pkey on chats | Index Scan using users_pkey on users | Membership rows are scanned, followed by indexed lookups of chats and users. |
| R07 | Index Scan using chat_members_pkey on chat_members | Index Scan using users_pkey on users | The composite membership primary key and user primary key support targeted lookups. |
| R08 | Seq Scan on messages | Seq Scan on message_receipts | Large receipt and message scans are needed to identify undelivered records and order them. |
| R09 | Seq Scan on media | Media rows must be aggregated by uploader and ranked by total storage. |
| R10 | Seq Scan on messages | The date cast on sent_at and daily aggregation require scanning messages. |
| R11 | Seq Scan on chat_members | Seq Scan on calls | Calls and memberships are scanned before filtering missed calls for the user. |
| R12 | Seq Scan on messages | Forwarding activity is grouped by sender and date, requiring a message-table scan. |
| R13 | Seq Scan on messages | The query scans messages and evaluates a NOT IN subquery; NULL semantics require review. |
| R14 | Seq Scan on messages | Seq Scan on chats | Messages are scanned and grouped by chat with distinct-sender counting and ranking. |
| R15 | Index Only Scan using blocked_users_pkey on blocked_users | The composite blocked-users primary key supports a very selective index-only lookup. |
| R16 | Index Scan using message_receipts_pkey on message_receipts | Index Scan using users_pkey on users | The message receipt primary key and users primary key support targeted lookups. |
| R17 | Seq Scan on message_receipts | Seq Scan on messages | Receipts and messages are scanned and joined before date filtering and aggregation. |
| R18 | Seq Scan on chat_members | Seq Scan on chats | Seq Scan on users | Users, memberships and chats are scanned to identify inactive group participants. |
| R19 | Seq Scan on chats | Seq Scan on messages | Two correlated subqueries repeatedly inspect messages for each group; this is the dominant baseline bottleneck. |
| R20 | Seq Scan on messages | All messages are read and grouped by extracted hour and type. |
| R21 | Seq Scan on messages | All message rows are aggregated to calculate edited and deleted percentages. |
| R22 | Index Scan using messages_pkey on messages | The primary-key index provides ordering, but OFFSET 100000 still skips many rows. |
| R23 | Seq Scan on devices | Device rows are scanned and filtered by device type and last-active time. |
| R24 | Seq Scan on media | Media rows are grouped by SHA-256 to find duplicates. |
| R25 | Index Scan using messages_pkey on messages | The message primary key supports efficient recursive reply-chain lookups. |
| W01 | (no scan) | A single-row INSERT uses defaults for omitted NOT NULL boolean flags. |
| W02 | Seq Scan on messages | Index Scan using message_receipts_pkey on message_receipts | Messages are scanned and matching receipt records are updated through the primary key. |
| W03 | Index Scan using messages_pkey on messages | The primary key locates the single message being updated. |
| W04 | (no scan) | The INSERT generates recipient rows using generate_series. |
| W05 | Index Scan using chat_members_pkey on chat_members | The composite membership primary key locates the user-chat membership. |

## 4. Key baseline findings

- The slowest query is R19, averaging 19163.481 ms.
- The next slowest query is R20, averaging 48.483 ms.
- The fastest query is R15, averaging 0.036 ms.
- R19 is a priority candidate for query optimization because its correlated message subqueries produce repeated work.
- R04 uses a leading-wildcard ILIKE search, which is a candidate for full-text or trigram indexing.
- R22 uses deep OFFSET pagination, which may become more expensive as the dataset grows.
- R13 uses NOT IN with a nullable subquery column. Its NULL semantics should be investigated and its results verified before rewriting.

## 5. Raw execution plan files

The `benchmarks/results/baseline/` directory contains `summary.csv` and three-run raw plan files for R01–R25 and W01–W05.

## 6. Measurement scope and limitations

These measurements describe the current local seed-data environment. Results may vary with hardware, cache state and database load. They are baseline measurements, not optimized-query results.

The baseline workload and data are retained for comparison during CP3 optimization.
