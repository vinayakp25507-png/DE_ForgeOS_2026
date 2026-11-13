CREATE SCHEMA IF NOT EXISTS whatsapp;
SET search_path TO whatsapp;

CREATE TABLE users (
    user_id BIGINT PRIMARY KEY CHECK (user_id > 0),
    phone_e164 VARCHAR(16) NOT NULL UNIQUE CHECK (phone_e164 ~ '^\+[1-9][0-9]{1,14}$'),
    display_name TEXT NOT NULL CHECK (length(trim(display_name)) > 0),
    about TEXT,
    is_business BOOLEAN NOT NULL,
    joined_on DATE NOT NULL,
    last_seen_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'BANNED', 'DELETED'))
);

CREATE TABLE devices (
    device_id BIGINT PRIMARY KEY CHECK (device_id > 0),
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    device_type TEXT NOT NULL CHECK (device_type IN ('ANDROID', 'DESKTOP', 'IOS', 'WEB')),
    app_version TEXT NOT NULL CHECK (app_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
    registered_at TIMESTAMPTZ NOT NULL,
    last_active_at TIMESTAMPTZ NOT NULL,
    CHECK (last_active_at >= registered_at)
);

CREATE TABLE chats (
    chat_id BIGINT PRIMARY KEY CHECK (chat_id > 0),
    chat_type TEXT NOT NULL CHECK (chat_type IN ('DIRECT', 'GROUP')),
    group_name TEXT,
    created_by BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL,
    CHECK ((chat_type = 'GROUP' AND group_name IS NOT NULL AND length(trim(group_name)) > 0)
        OR (chat_type = 'DIRECT' AND group_name IS NULL))
);

CREATE TABLE chat_members (
    chat_id BIGINT NOT NULL REFERENCES chats(chat_id) ON DELETE RESTRICT,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    role TEXT NOT NULL CHECK (role IN ('ADMIN', 'MEMBER')),
    joined_at TIMESTAMPTZ NOT NULL,
    left_at TIMESTAMPTZ,
    is_muted BOOLEAN NOT NULL,
    PRIMARY KEY (chat_id, user_id),
    CHECK (left_at IS NULL OR left_at >= joined_at)
);

CREATE TABLE media (
    media_id BIGINT PRIMARY KEY CHECK (media_id > 0),
    uploader_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    media_type TEXT NOT NULL CHECK (media_type IN ('AUDIO', 'DOCUMENT', 'IMAGE', 'VIDEO')),
    mime_type TEXT NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
    sha256 CHAR(64) NOT NULL CHECK (sha256 ~ '^[0-9a-fA-F]{64}$'),
    uploaded_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE messages (
    message_id BIGINT PRIMARY KEY CHECK (message_id > 0),
    chat_id BIGINT NOT NULL REFERENCES chats(chat_id) ON DELETE RESTRICT,
    sender_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    sent_at TIMESTAMPTZ NOT NULL,
    message_type TEXT NOT NULL CHECK (message_type IN ('AUDIO', 'DOCUMENT', 'IMAGE', 'LOCATION', 'TEXT', 'VIDEO')),
    body TEXT,
    media_id BIGINT REFERENCES media(media_id) ON DELETE RESTRICT,
    reply_to_message_id BIGINT REFERENCES messages(message_id) ON DELETE RESTRICT,
    is_forwarded BOOLEAN NOT NULL,
    is_deleted BOOLEAN NOT NULL,
    edited_at TIMESTAMPTZ,
    CHECK (NOT is_deleted OR body IS NULL),
    CHECK (edited_at IS NULL OR edited_at >= sent_at),
    CHECK (reply_to_message_id IS NULL OR reply_to_message_id <> message_id)
);

CREATE TABLE message_receipts (
    message_id BIGINT NOT NULL REFERENCES messages(message_id) ON DELETE RESTRICT,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    PRIMARY KEY (message_id, user_id),
    CHECK (read_at IS NULL OR (delivered_at IS NOT NULL AND read_at >= delivered_at))
);

CREATE TABLE calls (
    call_id BIGINT PRIMARY KEY CHECK (call_id > 0),
    chat_id BIGINT NOT NULL REFERENCES chats(chat_id) ON DELETE RESTRICT,
    caller_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    call_type TEXT NOT NULL CHECK (call_type IN ('VIDEO', 'VOICE')),
    started_at TIMESTAMPTZ NOT NULL,
    answered_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('COMPLETED', 'FAILED', 'MISSED', 'REJECTED')),
    CHECK (answered_at IS NULL OR answered_at >= started_at),
    CHECK (ended_at IS NULL OR ended_at >= started_at),
    CHECK (ended_at IS NULL OR answered_at IS NULL OR ended_at >= answered_at)
);

CREATE TABLE blocked_users (
    blocker_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    blocked_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    blocked_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);
