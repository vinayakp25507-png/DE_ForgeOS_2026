-- CP1 regression test: Media metadata integrity
SET search_path TO whatsapp;

DO $$
DECLARE failures BIGINT;
BEGIN
    SELECT COUNT(*) INTO failures
    FROM (

        SELECT 1 FROM media m
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = m.uploader_id)
           OR m.media_type NOT IN ('AUDIO','DOCUMENT','IMAGE','VIDEO')
           OR m.size_bytes <= 0
           OR m.sha256 !~ '^[0-9a-fA-F]{64}$'

    ) AS failed_checks;

    IF failures > 0 THEN
        RAISE EXCEPTION 'Media metadata integrity: % failure(s)', failures;
    END IF;

    RAISE NOTICE 'PASS: Media metadata integrity';
END $$;

-- File use case: validate uploader references, media categories, positive
-- sizes, and 64-character hexadecimal hashes; failures counts bad rows.
