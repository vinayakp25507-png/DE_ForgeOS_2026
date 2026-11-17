-- CP1 regression test: Thirty CHECK constraints
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    -- This count is a schema-drift guard; entity tests check representative row rules.
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

-- File use case: verify the expected CHECK-constraint count. failures signals
-- count drift; per-entity integrity scripts exercise representative row rules.
