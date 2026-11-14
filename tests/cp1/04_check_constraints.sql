-- CP1 regression test: Thirty CHECK constraints
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM pg_constraint c
           JOIN pg_namespace n ON n.oid = c.connamespace
           WHERE n.nspname = 'whatsapp' AND c.contype = 'c') <> 30

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Thirty CHECK constraints: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Thirty CHECK constraints';
END $$;
