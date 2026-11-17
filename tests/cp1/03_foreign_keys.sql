-- CP1 regression test: Fifteen foreign keys
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 WHERE
          (SELECT COUNT(*) FROM pg_constraint c
           JOIN pg_namespace n ON n.oid = c.connamespace
           WHERE n.nspname = 'whatsapp' AND c.contype = 'f') <> 15

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Fifteen foreign keys: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Fifteen foreign keys';
END $$;

-- File use case: verify that the whatsapp schema retains all 15 expected
-- foreign-key constraints; failures is the catalog-count mismatch indicator.
