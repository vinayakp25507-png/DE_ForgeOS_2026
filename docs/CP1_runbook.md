# CP1 Database Execution Runbook

## Prerequisites
- PostgreSQL installed and running.
- psql command-line client available.
- Seed CSV files extracted into seed_data/.
- Commands executed from the repository root.

## Database Connection
Use the configured PostgreSQL connection:
- Host: localhost
- Port: 5433
- User: postgres
- Database: whatsapp

## Execution Steps

1. Create the database named whatsapp if it does not already exist.
2. Run sql/01_schema.sql to create the nine database tables.
3. Run sql/02_load_data.sql to load the seed CSV files.
4. Verify all tables using psql command \dt whatsapp.*.
5. Run sql/03_validate_data.sql to check row counts, foreign-key integrity and message data quality.
6. Run sql/04_constraint_audit.sql to verify schema constraints.

## Validated Seed Dataset

| Table | Rows |
|---|---:|
| users | 30,000 |
| devices | 42,000 |
| chats | 23,000 |
| chat_members | 104,514 |
| media | 27,634 |
| messages | 120,000 |
| message_receipts | 501,590 |
| calls | 25,000 |
| blocked_users | 4,000 |
| Total | 877,738 |

## Validation Evidence
- Nine tables were present in the database.
- All 15 foreign-key checks reported zero violations.
- Constraint audit confirmed 9 primary keys, 15 foreign keys,
  30 CHECK constraints, 1 UNIQUE constraint and 46 NOT NULL columns.

## CP1 Completion Checklist
- [ ] Schema executes without errors.
- [ ] Seed data loads successfully.
- [ ] All nine tables are present.
- [ ] Foreign-key validation passes.
- [ ] Constraint audit passes.
- [ ] ER diagram and project documentation are available.
- [ ] Seed CSV files are excluded from Git.
