-- CP3: workload-driven PostgreSQL indexes
-- Every index below supports a specific read-query access path.


-- R01, R02: user chat membership and latest messages per chat
CREATE INDEX IF NOT EXISTS idx_chat_members_user_active_chat
ON whatsapp.chat_members (user_id, chat_id)
WHERE left_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_messages_chat_sent_desc
ON whatsapp.messages (chat_id, sent_at DESC);

-- R03: unread receipt lookup for one user
CREATE INDEX IF NOT EXISTS idx_receipts_unread_user_message
ON whatsapp.message_receipts (user_id, message_id)
WHERE read_at IS NULL;


-- R08: undelivered receipt lookup
CREATE INDEX IF NOT EXISTS idx_receipts_undelivered_message
ON whatsapp.message_receipts (message_id)
WHERE delivered_at IS NULL;

-- R10, R14, R17: date range filtering on messages
CREATE INDEX IF NOT EXISTS idx_messages_sent_at
ON whatsapp.messages (sent_at);


-- R11: missed calls ordered and filtered by start time
CREATE INDEX IF NOT EXISTS idx_calls_missed_started_chat
ON whatsapp.calls (started_at DESC, chat_id)
WHERE status = 'MISSED';

-- R23: inactive web and desktop device lookup
CREATE INDEX IF NOT EXISTS idx_devices_web_desktop_activity
ON whatsapp.devices (last_active_at)
WHERE device_type IN ('WEB', 'DESKTOP');

-- File use case: add the CP3 workload indexes after the baseline run.
-- The query labels above explain each access path; indexes trade storage and
-- faster reads for additional maintenance on inserts and updates.
