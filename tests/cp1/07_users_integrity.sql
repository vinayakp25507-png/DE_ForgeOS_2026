-- CP1 regression test: User data integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM users
        WHERE user_id <= 0
           OR phone_e164 !~ '^\+[1-9][0-9]{1,14}$'
           OR length(trim(display_name)) = 0
        UNION ALL
        SELECT 1 FROM (
          SELECT phone_e164 FROM users
          GROUP BY phone_e164 HAVING COUNT(*) > 1
        ) duplicates

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'User data integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: User data integrity';
END $$;
