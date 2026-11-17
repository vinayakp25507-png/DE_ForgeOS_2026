SET search_path TO whatsapp;

DO $$
DECLARE
    t INT;
    pk INT;
    fk INT;
    ck INT;
    uq INT;
    nn INT;
BEGIN
    SELECT COUNT(*) INTO t
    FROM information_schema.tables
    WHERE table_schema = 'whatsapp'
      AND table_type = 'BASE TABLE';

    SELECT
        COUNT(*) FILTER (WHERE contype = 'p'),
        COUNT(*) FILTER (WHERE contype = 'f'),
        COUNT(*) FILTER (WHERE contype = 'c'),
        COUNT(*) FILTER (WHERE contype = 'u')
    INTO pk, fk, ck, uq
    FROM pg_constraint con
    JOIN pg_class r ON r.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = r.relnamespace
    WHERE n.nspname = 'whatsapp';

    SELECT COUNT(*) INTO nn
    FROM pg_attribute a
    JOIN pg_class r ON r.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = r.relnamespace
    WHERE n.nspname = 'whatsapp'
      AND r.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attnotnull;

    RAISE NOTICE 'Tables: %, PK: %, FK: %, CHECK: %, UNIQUE: %, NOT NULL: %',
        t, pk, fk, ck, uq, nn;

    IF t <> 9 OR pk <> 9 OR fk <> 15 OR ck <> 30 OR uq <> 1 OR nn <> 46 THEN
        RAISE EXCEPTION 'Constraint audit failed';
    END IF;

    RAISE NOTICE 'PASS: All expected constraints verified.';
END $$;

-- File use case: fail fast if the live schema's constraint inventory drifts
-- from the expected design. In the DO block, t/pk/fk/ck/uq/nn hold catalog
-- counts for tables, keys, checks, uniqueness, and NOT NULL attributes.
