# Database Data Validation Report

## 1. Overview

Validation was performed against the PostgreSQL database `whatsapp`.

- Tables checked: 9
- Total records: 877,738
- Foreign-key relationships checked: 15
- Validation date: 13 November 2026

## 2. Table Row Counts

| Table | Records |
|---|---:|
| users | 30,000 |
| devices | 42,000 |
| chats | 23,000 |
| chat_members | 104,514 |
| media | 27,634 |
| messages | 120,000 |
| message_receipts | 501,590 |
| calls | 25,000 |
| blocked_users | 4,000 |
| **Total** | **877,738** |

## 3. Foreign-Key Integrity

All 15 foreign-key checks returned zero orphan records.

| Relationship | Violations | Result |
|---|---:|---|
| devices.user_id | 0 | PASS |
| chats.created_by | 0 | PASS |
| chat_members.chat_id | 0 | PASS |
| chat_members.user_id | 0 | PASS |
| media.uploader_id | 0 | PASS |
| messages.chat_id | 0 | PASS |
| messages.sender_id | 0 | PASS |
| messages.media_id | 0 | PASS |
| messages.reply_to_message_id | 0 | PASS |
| message_receipts.message_id | 0 | PASS |
| message_receipts.user_id | 0 | PASS |
| calls.chat_id | 0 | PASS |
| calls.caller_id | 0 | PASS |
| blocked_users.blocker_id | 0 | PASS |
| blocked_users.blocked_id | 0 | PASS |

## 4. Message Data Quality

| Message Type | Total | Without Media | Without Body |
|---|---:|---:|---:|
| AUDIO | 7,178 | 163 | 7,178 |
| DOCUMENT | 3,665 | 72 | 3,665 |
| IMAGE | 12,121 | 236 | 8,531 |
| LOCATION | 2,391 | 2,391 | 36 |
| TEXT | 89,975 | 89,975 | 1,747 |
| VIDEO | 4,670 | 86 | 4,670 |

These NULL patterns are observations from the loaded dataset and are not automatically classified as constraint violations.

## 5. Location Message Review

| Deleted Status | Total | NULL Body | NULL Media |
|---|---:|---:|---:|
| Active | 2,355 | 0 | 2,355 |
| Deleted | 36 | 36 | 36 |

## 6. Conclusion

The validation queries found no orphan records across the 15 checked foreign-key relationships. The message analysis also documented NULL patterns for each message type and separately reviewed location messages.

The SQL validation queries are available in `sql/03_validate_data.sql`.
