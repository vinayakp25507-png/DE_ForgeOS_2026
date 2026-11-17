-- CP1 regression test: Device data integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM devices d
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = d.user_id)
           OR d.device_type NOT IN ('ANDROID','DESKTOP','IOS','WEB')
           OR d.app_version !~ '^[0-9]+\.[0-9]+\.[0-9]+$'
           OR d.last_active_at < d.registered_at

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Device data integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Device data integrity';
END $$;

-- File use case: validate device ownership, allowed platform/version values,
-- and registration/activity timestamp order; failures counts invalid rows.
