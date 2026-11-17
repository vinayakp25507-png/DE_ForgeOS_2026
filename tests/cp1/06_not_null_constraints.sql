-- CP1 regression test: Forty-six NOT NULL columns
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM pg_attribute a
           JOIN pg_class r ON r.oid = a.attrelid
           JOIN pg_namespace n ON n.oid = r.relnamespace
           WHERE n.nspname = 'whatsapp' AND r.relkind = 'r'
             AND a.attnum > 0 AND NOT a.attisdropped
             AND a.attnotnull) <> 46

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Forty-six NOT NULL columns: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Forty-six NOT NULL columns';
END $$;

-- File use case: guard the expected count of required (NOT NULL) attributes.
-- failures is set from PostgreSQL's live catalog, not from table data.
