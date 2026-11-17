# Viva Preparation Guide

This guide explains the database project in terms of its requirements, design
choices, validation, performance work, and limitations. Use it to prepare your
own explanations; the measured reports and SQL files remain the evidence.

## 1. Project in one minute

This project models a WhatsApp-style messaging database in PostgreSQL. It
reconstructs a schema from CSV exports, enforces data integrity, checks the
loaded data, measures a fixed 30-query workload, and tests selected
optimizations and a larger-data partitioning experiment.

The main trade-off is between correctness, query latency, write cost, and
operational complexity. An optimization is useful only when its result is
correct and its plan or repeated timings support the change.

## 2. Requirements and use cases

| Requirement | Example use case | Main data |
|---|---|---|
| Open a chat and show recent messages | Load the newest messages in a group | `chats`, `chat_members`, `messages` |
| Track delivery and reads per recipient | Show pending receipts or blue ticks | `messages`, `message_receipts` |
| Support direct and group conversations | List current members and roles | `chats`, `chat_members`, `users` |
| Store media without repeating file metadata | Find large uploads or duplicate files | `media`, `messages` |
| Support replies, edits, forwarding, and deletion | Walk a reply chain or honor delete-for-everyone | `messages` |
| Support calls and privacy controls | Find missed calls or check a block relationship | `calls`, `blocked_users` |
| Support product and operations reporting | Measure daily activity, read time, or inactive devices | Messages, receipts, devices, and calls |

The stakeholders include end users, group administrators, the delivery service,
storage, trust and safety, product analytics, and the security/platform teams.
The detailed problem-to-query mapping is in
[`01_problem_understanding.md`](./01_problem_understanding.md).

## 3. Data model and key relationships

The schema has nine tables:

- `users` stores account identity and profile data; `phone_e164` is unique.
- `devices` is one-to-many from users: one user may have several linked devices.
- `chats` stores direct or group conversation metadata.
- `chat_members` is the many-to-many bridge between users and chats. Its
  `(chat_id, user_id)` primary key prevents duplicate membership rows; `left_at`
  retains membership history.
- `media` stores file metadata separately from messages.
- `messages` belongs to a chat and sender. Its optional self-reference
  `reply_to_message_id` supports reply threads.
- `message_receipts` records delivery/read state per `(message_id, user_id)`.
- `calls` records call events linked to a chat and caller.
- `blocked_users` is a directed user-to-user relationship with a composite key.

The primary/foreign-key map and ER diagram are in
[`02_schema_design.md`](./02_schema_design.md) and `diagrams/`.

## 4. Why these constraints and nullable fields matter

- Primary keys identify each entity; composite keys prevent duplicate
  memberships, receipts, and block pairs.
- Foreign keys prevent orphan references. `ON DELETE RESTRICT` protects records
  that are still referenced by messages, receipts, or other entities.
- `CHECK` constraints encode domain rules such as allowed statuses, positive
  IDs, valid phone/hash formats, and timestamp ordering.
- Optional timestamps such as `left_at`, `delivered_at`, `read_at`, and
  `last_seen_at` represent events that may not have happened yet.
- `group_name` is required for a group and absent for a direct chat.
- A deleted message must not retain its body. A media reference is optional
  because the provided data contains non-text messages without one.
- Receipt data is recipient-specific, so delivery/read timestamps belong in
  `message_receipts`, not as a single timestamp on `messages`.

The project reports 9 primary keys, 15 foreign keys, 30 checks, one additional
unique constraint, and 46 NOT NULL columns. The seed contains 877,738 rows
across the nine tables; validation found no orphan foreign-key references.

## 5. Workflow and evidence

1. `sql/01_schema.sql` creates the schema and constraints.
2. `sql/02_load_data.sql` loads the nine CSVs in parent-before-child order.
3. `sql/03_validate_data.sql` checks row counts, references, and data patterns.
4. `sql/04_constraint_audit.sql` checks the expected constraint inventory.
5. `queries/workload_30.sql` is the fixed baseline workload: 25 reads and five
   writes. The write statements are measured inside a transaction and rolled
   back.
6. `sql/05_indexes.sql` defines workload-driven indexes;
   `sql/06_optimized_queries.sql` contains the optimized workload.
7. `sql/08_partitioning.sql` creates isolated benchmark copies for the
   scalability experiment; it does not replace the production `messages` table.

Run commands and dataset prerequisites are documented in
[`CP1_runbook.md`](./CP1_runbook.md), [`03_baseline_timings.md`](./03_baseline_timings.md),
and the phase reports. The benchmark scripts use `EXPLAIN (ANALYZE, BUFFERS)`;
read both the plans and repeated timings rather than relying on one run.

## 6. Optimization decisions to explain

### R19: aggregate once instead of rescanning per group

The baseline uses correlated subqueries to find each group's latest message and
June count. The optimized query aggregates `messages` once by `chat_id`, then
left-joins those results to groups. In the recorded seed benchmark, the average
changed from 19,163.481 ms to 15.936 ms (about 1,202.53x faster). The exact
measurements and plans are in [`04_optimization_report.md`](./04_optimization_report.md).

### R10: preserve a searchable timestamp range

The optimized filter uses a half-open range on `sent_at` rather than converting
each timestamp in the predicate. The range includes all of June while allowing
the planner to consider an index on `sent_at`.

### R13: correctness before equivalence

The original `NOT IN` subquery can produce UNKNOWN when its result contains
NULL, hiding questions that have no replies. `NOT EXISTS` checks for an
actual matching reply and returns the intended unanswered questions. This is
an intentional correctness fix: the report records seven rows from the
corrected query versus zero from the NULL-affected original, so this one query
is not result-equivalent to the flawed original.

### Indexes have trade-offs

Indexes can reduce reads for selective lookups and ordered access, but they
consume storage and add work to inserts/updates. Some measured queries became
slower after the optimization set. Explain each index through the access path
it supports and acknowledge write overhead; do not claim every query improved.

## 7. Scalability experiment and limitation

The checked-in CP4 experiment compares an unpartitioned control with an
eight-way `HASH(message_id)` copy containing 600,000 rows each (five times the
120,000-message seed). The hash key preserves a single-column primary key,
which is important because messages are self-referenced and receipts refer to
`message_id`.

This experiment does **not** show a win for the tested queries: all eight
recorded read-query shapes were slower on the partitioned copy. Most filter on
`chat_id` or `sent_at`, not `message_id`, so hash partitioning cannot prune to
one partition for those predicates. The result supports a cautious conclusion:
this partition key is not a recommendation for those access paths. The test is
also only 5x and read-focused; it is not proof of 20x production readiness.
See [`05_scalability_report.md`](./05_scalability_report.md) for timings and
limitations.

## 8. Common viva questions

**Why separate `chat_members` from `chats` and `users`?**  
Users can join multiple chats and each chat can contain multiple users, so the
relationship is many-to-many. The bridge table stores membership attributes
without duplicating user or chat data.

**Why use a composite key for receipts?**  
Each recipient should have at most one receipt row per message. The pair
`(message_id, user_id)` expresses that identity.

**Why are read and delivery timestamps nullable?**  
NULL means the corresponding event has not happened yet. If a read timestamp
exists, a delivery timestamp must exist and must be no later than the read.

**Why does the schema use `RESTRICT` on deletes?**  
Deleting a referenced user, chat, or message could silently invalidate history
or receipts. `RESTRICT` requires an explicit, reviewed lifecycle policy.

**Why can an image/video message have no `media_id`?**  
The supplied dataset contains such rows. The schema preserves valid input
rather than imposing an unsupported assumption that every non-text message has
a media record.

**What is the difference between an index and a constraint?**  
A constraint enforces correctness (for example uniqueness or referential
integrity). PostgreSQL may create an index to implement a primary/unique key;
workload indexes are added separately for access performance.

**Why use `NOT EXISTS` for R13?**  
It asks whether a matching reply exists. Unlike `NOT IN`, it does not let an
unrelated NULL in the subquery make the condition UNKNOWN.

**Why didn't hash partitioning improve the tested workload?**  
Hash partitioning is on `message_id`, while most tested predicates use
`chat_id` or `sent_at`; those queries still visit multiple partitions and pay
partition overhead.

**What is the most important performance result?**  
R19's pre-aggregation removed repeated per-group message work and produced the
largest measured seed-data improvement. The full report includes the plan and
timing evidence.

## 9. Before the viva

- Be able to draw the ER relationships and explain each composite key.
- Explain one business rule from a `CHECK` constraint and one nullable field.
- Trace one query from its use case to its plan, index, and measured result.
- Explain the R13 NULL issue and why its output intentionally changed.
- State the partition experiment's key, scale, result, and limitations honestly.
- Use the committed SQL and reports as evidence; do not quote a number without
  identifying its dataset and benchmark method.
