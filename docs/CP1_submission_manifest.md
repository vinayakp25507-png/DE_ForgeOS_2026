# CP1 Submission Manifest

## Required CP1 Deliverables

| Deliverable | Repository Path | Purpose |
|---|---|---|
| Problem Understanding | docs/01_problem_understanding.md | Problem, stakeholders and assumptions |
| Schema Design | docs/02_schema_design.md | Entities, relationships and normalization |
| Database Schema | sql/01_schema.sql | PostgreSQL table definitions and constraints |
| Data Loading | sql/02_load_data.sql | Seed CSV loading workflow |
| ER Diagram | diagrams/er_diagram.png | Visual representation of database entities and relationships |

## Additional Verification Evidence

| Evidence | File |
|---|---|
| Data validation queries | sql/03_validate_data.sql |
| Constraint audit | sql/04_constraint_audit.sql |
| Data validation report | docs/03_data_validation.md |
| Database execution instructions | docs/CP1_runbook.md |

## Verified Database Results

- Tables present: 9
- Total seed records: 877,738
- Foreign-key relationships checked: 15
- Foreign-key violations: 0
- Primary keys: 9
- CHECK constraints: 30
- UNIQUE constraints: 1
- NOT NULL columns: 46

## Final Submission Review

Before CP1 submission:
- Verify all five mandatory deliverables exist on the default branch.
- Test schema creation on a clean database.
- Verify successful seed data loading.
- Run data validation and constraint audit.
- Confirm the ER diagram matches the relational schema.
- Ensure seed CSV files are excluded from Git.

This manifest provides traceability between CP1 requirements, repository files and validation evidence.
