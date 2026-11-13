\set ON_ERROR_STOP on

BEGIN;

SET search_path TO whatsapp;

\echo 'Loading users...'
\copy whatsapp.users (user_id, phone_e164, display_name, about, is_business, joined_on, last_seen_at, status) FROM 'seed_data/users.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading devices...'
\copy whatsapp.devices (device_id, user_id, device_type, app_version, registered_at, last_active_at) FROM 'seed_data/devices.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading chats...'
\copy whatsapp.chats (chat_id, chat_type, group_name, created_by, created_at) FROM 'seed_data/chats.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading chat_members...'
\copy whatsapp.chat_members (chat_id, user_id, role, joined_at, left_at, is_muted) FROM 'seed_data/chat_members.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading media...'
\copy whatsapp.media (media_id, uploader_id, media_type, mime_type, size_bytes, sha256, uploaded_at) FROM 'seed_data/media.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading messages...'
\copy whatsapp.messages (message_id, chat_id, sender_id, sent_at, message_type, body, media_id, reply_to_message_id, is_forwarded, is_deleted, edited_at) FROM 'seed_data/messages.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading message_receipts...'
\copy whatsapp.message_receipts (message_id, user_id, delivered_at, read_at) FROM 'seed_data/message_receipts.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading calls...'
\copy whatsapp.calls (call_id, chat_id, caller_id, call_type, started_at, answered_at, ended_at, status) FROM 'seed_data/calls.csv' WITH (FORMAT csv, HEADER true);

\echo 'Loading blocked_users...'
\copy whatsapp.blocked_users (blocker_id, blocked_id, blocked_at) FROM 'seed_data/blocked_users.csv' WITH (FORMAT csv, HEADER true);

COMMIT;

\echo 'All nine CSV files loaded successfully.'
