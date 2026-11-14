-- CP1 regression test: Receipt integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM message_receipts r
        WHERE NOT EXISTS (SELECT 1 FROM messages m WHERE m.message_id = r.message_id)
           OR NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = r.user_id)
           OR (r.read_at IS NOT NULL AND r.delivered_at IS NULL)
           OR (r.read_at IS NOT NULL AND r.read_at < r.delivered_at)

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Receipt integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Receipt integrity';
END $$;
