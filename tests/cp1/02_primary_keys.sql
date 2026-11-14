-- CP1 regression test: Primary keys
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM pg_constraint c
           JOIN pg_namespace n ON n.oid = c.connamespace
           WHERE n.nspname = 'whatsapp' AND c.contype = 'p') <> 9
        UNION ALL
        SELECT 1 FROM (VALUES
          ('users'),('devices'),('chats'),('chat_members'),('media'),
          ('messages'),('message_receipts'),('calls'),('blocked_users')
        ) AS e(table_name)
        WHERE NOT EXISTS (
          SELECT 1 FROM pg_constraint c
          JOIN pg_class r ON r.oid = c.conrelid
          JOIN pg_namespace n ON n.oid = r.relnamespace
          WHERE n.nspname = 'whatsapp'
            AND r.relname = e.table_name AND c.contype = 'p'
        )

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Primary keys: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Primary keys';
END $$;
