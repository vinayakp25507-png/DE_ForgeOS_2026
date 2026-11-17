-- CP1 regression test: Nine required tables
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM information_schema.tables
           WHERE table_schema = 'whatsapp' AND table_type = 'BASE TABLE') <> 9
        UNION ALL
        SELECT 1 FROM (VALUES
          ('users'),('devices'),('chats'),('chat_members'),('media'),
          ('messages'),('message_receipts'),('calls'),('blocked_users')
        ) AS e(table_name)
        WHERE NOT EXISTS (
          SELECT 1 FROM information_schema.tables t
          WHERE t.table_schema = 'whatsapp'
            AND t.table_name = e.table_name
            AND t.table_type = 'BASE TABLE'
        )

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Nine required tables: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Nine required tables';
END $$;

-- File use case: catch missing or unexpected base tables in whatsapp.
-- failures counts both a wrong table total and any absent required table name.
