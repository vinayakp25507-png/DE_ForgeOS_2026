-- CP1 seed dataset summary. Reports actual counts; does not modify data.
SET search_path TO whatsapp;

SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'devices', COUNT(*) FROM devices
UNION ALL SELECT 'chats', COUNT(*) FROM chats
UNION ALL SELECT 'chat_members', COUNT(*) FROM chat_members
UNION ALL SELECT 'media', COUNT(*) FROM media
UNION ALL SELECT 'messages', COUNT(*) FROM messages
UNION ALL SELECT 'message_receipts', COUNT(*) FROM message_receipts
UNION ALL SELECT 'calls', COUNT(*) FROM calls
UNION ALL SELECT 'blocked_users', COUNT(*) FROM blocked_users
ORDER BY table_name;
