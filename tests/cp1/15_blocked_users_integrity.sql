-- CP1 regression test: Blocked user integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM blocked_users b
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = b.blocker_id)
           OR NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = b.blocked_id)
           OR b.blocker_id = b.blocked_id

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Blocked user integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Blocked user integrity';
END $$;

-- File use case: validate both user references and prohibit self-blocking.
-- failures counts invalid directed blocker/blocked pairs.
