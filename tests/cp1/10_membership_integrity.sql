-- CP1 regression test: Chat membership integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM chat_members cm
        WHERE NOT EXISTS (SELECT 1 FROM chats c WHERE c.chat_id = cm.chat_id)
           OR NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = cm.user_id)
           OR cm.role NOT IN ('ADMIN','MEMBER')
           OR (cm.left_at IS NOT NULL AND cm.left_at < cm.joined_at)

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Chat membership integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Chat membership integrity';
END $$;

-- File use case: validate membership references, roles, and join/leave order.
-- failures counts rows that violate any membership rule.
