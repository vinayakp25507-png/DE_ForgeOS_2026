-- CP1 regression test: Call integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM calls c
        WHERE NOT EXISTS (SELECT 1 FROM chats ch WHERE ch.chat_id = c.chat_id)
           OR NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = c.caller_id)
           OR c.call_type NOT IN ('VIDEO','VOICE')
           OR c.status NOT IN ('COMPLETED','FAILED','MISSED','REJECTED')
           OR (c.answered_at IS NOT NULL AND c.answered_at < c.started_at)
           OR (c.ended_at IS NOT NULL AND c.ended_at < c.started_at)
           OR (c.ended_at IS NOT NULL AND c.answered_at IS NOT NULL
               AND c.ended_at < c.answered_at)

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Call integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Call integrity';
END $$;

-- File use case: validate call references, types/statuses, and event ordering.
-- failures counts calls with a missing parent or invalid timeline.
