-- CP1 regression test: Unique phone constraint
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM pg_constraint c
           JOIN pg_namespace n ON n.oid = c.connamespace
           WHERE n.nspname = 'whatsapp' AND c.contype = 'u') <> 1
        UNION ALL
        SELECT 1 WHERE NOT EXISTS (
          SELECT 1 FROM pg_constraint c
          JOIN pg_class r ON r.oid = c.conrelid
          JOIN pg_namespace n ON n.oid = r.relnamespace
          WHERE n.nspname = 'whatsapp'
            AND r.relname = 'users' AND c.contype = 'u'
            AND pg_get_constraintdef(c.oid) LIKE '%phone_e164%'
        )

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Unique phone constraint: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Unique phone constraint';
END $$;
