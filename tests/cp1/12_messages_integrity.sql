-- CP1 regression test: Message integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    -- Nullable references are checked only when present; deleted messages must clear body text.
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM messages m
        WHERE NOT EXISTS (SELECT 1 FROM chats c WHERE c.chat_id = m.chat_id)
           OR NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = m.sender_id)
           OR (m.media_id IS NOT NULL AND NOT EXISTS
               (SELECT 1 FROM media md WHERE md.media_id = m.media_id))
           OR (m.reply_to_message_id IS NOT NULL AND NOT EXISTS
               (SELECT 1 FROM messages r WHERE r.message_id = m.reply_to_message_id))
           OR m.message_type NOT IN
               ('AUDIO','DOCUMENT','IMAGE','LOCATION','TEXT','VIDEO')
           OR (m.is_deleted AND m.body IS NOT NULL)
           OR (m.edited_at IS NOT NULL AND m.edited_at < m.sent_at)
           OR m.reply_to_message_id = m.message_id

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Message integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Message integrity';
END $$;

-- File use case: validate message references/types and deletion, edit, and
-- reply rules; failures counts messages that violate any listed invariant.
