# CP4 Scalability and Partitioning Report

## Objective

Compare an unpartitioned control relation with an eight-way HASH-partitioned relation using the same deterministic 5x message data.

## Partitioning design

The experiment partitions by HASH(message_id), not RANGE(sent_at). The source schema uses message_id as a single-column primary key and has self-referential and receipt foreign-key relationships on message_id. PostgreSQL partitioned unique/primary-key constraints must include the partition key; hash partitioning by message_id preserves this single-column key. Range partitioning by sent_at would require a wider primary key and changes to dependent foreign keys, so it is not applied to the existing production table.

The SQL creates two separate benchmark relations, messages_unpartitioned_large and messages_hash_partitioned. The production whatsapp.messages table is not replaced or altered. The benchmark data consists of the 120,000 source rows plus four deterministic replicas, giving 600,000 rows per benchmark relation. Replica IDs and self-reply references are remapped, and timestamps are shifted by whole months.

## Dataset and storage

| Relation | Rows |
|---|---:|
| unpartitioned | 600000 |
| hash_partitioned | 600000 |

## Benchmark method

Eight representative read-query shapes (L01-L08) were run three times against each relation using EXPLAIN (ANALYZE, BUFFERS). The complete CSV is `benchmarks/results/large/summary.csv`. Raw plans are saved as `Lxx_unpartitioned.txt` and `Lxx_hash_partitioned.txt` under `benchmarks/results/large/`.

## Results

| Query | Unpartitioned avg (ms) | Hash-partitioned avg (ms) | Partitioned speedup |
|---|---:|---:|---:|
| L01 | 0.237 | 0.692 | 0.34x |
| L02 | 7.558 | 9.377 | 0.81x |
| L03 | 40.026 | 51.484 | 0.78x |
| L04 | 0.044 | 0.087 | 0.51x |
| L05 | 29.781 | 39.018 | 0.76x |
| L06 | 67.931 | 114.389 | 0.59x |
| L07 | 14.562 | 20.823 | 0.70x |
| L08 | 40.903 | 57.906 | 0.71x |

## Interpretation

A speedup above 1.0x means the hash-partitioned copy was faster for that query; below 1.0x means it was slower. HASH(message_id) can prune partitions for predicates on message_id, but it cannot prune partitions for chat_id or sent_at filters. Those query shapes may scan all eight partitions. Do not claim universal partitioning improvement; use the paired timings and plans above.

## Operational considerations and limitations

- The experiment is isolated; the production whatsapp.messages table remains unchanged.
- The 5x dataset uses repeated source rows with remapped IDs and shifted timestamps. It is suitable for controlled scalability comparison, not a realistic model of future traffic distributions.
- More partitions add planning, vacuum/analyze, monitoring, and index-maintenance overhead.
- A production cutover requires a separately reviewed migration, FK validation, ID allocation strategy, and rollback plan.
- WRITE-heavy workload impact is not represented by the eight read-query shapes; retain separate write benchmarks before recommending production partitioning.

## Reproduction

1. Run `psql -h localhost -p 5433 -U postgres -d whatsapp -v ON_ERROR_STOP=1 -f sql/08_partitioning.sql`.
2. Run `PGHOST=localhost PGPORT=5433 PGUSER=postgres ./benchmarks/run_large_benchmark.sh whatsapp`.
3. Run `python3 benchmarks/finalize_large_report.py`.
