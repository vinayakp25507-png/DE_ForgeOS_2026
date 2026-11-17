-- CP1 regression test: Chat data integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM chats c
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = c.created_by)
           OR c.chat_type NOT IN ('DIRECT','GROUP')
           OR (c.chat_type = 'GROUP' AND
               (c.group_name IS NULL OR length(trim(c.group_name)) = 0))
           OR (c.chat_type = 'DIRECT' AND c.group_name IS NOT NULL)

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Chat data integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Chat data integrity';
END $$;

-- File use case: validate chat creators, DIRECT/GROUP types, and the rule
-- that only groups have a nonblank group_name; failures counts bad chats.
