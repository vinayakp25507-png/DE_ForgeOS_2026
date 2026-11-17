SET search_path TO whatsapp;

\echo '========== 1. TABLE ROW COUNTS =========='

SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL SELECT 'devices', COUNT(*) FROM devices
UNION ALL SELECT 'chats', COUNT(*) FROM chats
UNION ALL SELECT 'chat_members', COUNT(*) FROM chat_members
UNION ALL SELECT 'media', COUNT(*) FROM media
UNION ALL SELECT 'messages', COUNT(*) FROM messages
UNION ALL SELECT 'message_receipts', COUNT(*) FROM message_receipts
UNION ALL SELECT 'calls', COUNT(*) FROM calls
UNION ALL SELECT 'blocked_users', COUNT(*) FROM blocked_users
ORDER BY table_name;

\echo '========== 2. FOREIGN KEY INTEGRITY =========='

WITH fk_checks AS (
    SELECT 'devices.user_id' AS check_name, COUNT(*) AS violations
    FROM devices d LEFT JOIN users u ON d.user_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'chats.created_by', COUNT(*)
    FROM chats c LEFT JOIN users u ON c.created_by = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'chat_members.chat_id', COUNT(*)
    FROM chat_members cm LEFT JOIN chats c ON cm.chat_id = c.chat_id
    WHERE c.chat_id IS NULL

    UNION ALL
    SELECT 'chat_members.user_id', COUNT(*)
    FROM chat_members cm LEFT JOIN users u ON cm.user_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'media.uploader_id', COUNT(*)
    FROM media m LEFT JOIN users u ON m.uploader_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'messages.chat_id', COUNT(*)
    FROM messages m LEFT JOIN chats c ON m.chat_id = c.chat_id
    WHERE c.chat_id IS NULL

    UNION ALL
    SELECT 'messages.sender_id', COUNT(*)
    FROM messages m LEFT JOIN users u ON m.sender_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'messages.media_id', COUNT(*)
    FROM messages m LEFT JOIN media md ON m.media_id = md.media_id
    WHERE m.media_id IS NOT NULL AND md.media_id IS NULL

    UNION ALL
    SELECT 'messages.reply_to_message_id', COUNT(*)
    FROM messages m LEFT JOIN messages r ON m.reply_to_message_id = r.message_id
    WHERE m.reply_to_message_id IS NOT NULL AND r.message_id IS NULL

    UNION ALL
    SELECT 'message_receipts.message_id', COUNT(*)
    FROM message_receipts mr LEFT JOIN messages m ON mr.message_id = m.message_id
    WHERE m.message_id IS NULL

    UNION ALL
    SELECT 'message_receipts.user_id', COUNT(*)
    FROM message_receipts mr LEFT JOIN users u ON mr.user_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'calls.chat_id', COUNT(*)
    FROM calls ca LEFT JOIN chats c ON ca.chat_id = c.chat_id
    WHERE c.chat_id IS NULL

    UNION ALL
    SELECT 'calls.caller_id', COUNT(*)
    FROM calls ca LEFT JOIN users u ON ca.caller_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'blocked_users.blocker_id', COUNT(*)
    FROM blocked_users b LEFT JOIN users u ON b.blocker_id = u.user_id
    WHERE u.user_id IS NULL

    UNION ALL
    SELECT 'blocked_users.blocked_id', COUNT(*)
    FROM blocked_users b LEFT JOIN users u ON b.blocked_id = u.user_id
    WHERE u.user_id IS NULL
)
SELECT check_name, violations,
       CASE WHEN violations = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM fk_checks
ORDER BY check_name;

\echo '========== 3. MESSAGE DATA QUALITY =========='

SELECT
    message_type,
    COUNT(*) AS total_messages,
    COUNT(*) FILTER (WHERE media_id IS NULL) AS without_media,
    COUNT(*) FILTER (WHERE body IS NULL) AS without_body
FROM messages
GROUP BY message_type
ORDER BY message_type;

\echo '========== 4. LOCATION MESSAGE REVIEW =========='

SELECT
    is_deleted,
    COUNT(*) AS total_messages,
    COUNT(*) FILTER (WHERE body IS NULL) AS null_body,
    COUNT(*) FILTER (WHERE media_id IS NULL) AS null_media
FROM messages
WHERE message_type = 'LOCATION'
GROUP BY is_deleted
ORDER BY is_deleted;

\echo '========== VALIDATION COMPLETE =========='

-- File use case: report table counts, orphan foreign keys, and message NULL
-- patterns after loading. The CTE counts violations; these queries do not
-- modify data or assert that every optional field must be populated.
