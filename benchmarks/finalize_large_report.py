#!/usr/bin/env python3
"""Generate docs/05_scalability_report.md from measured CP4 large-scale CSV."""
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
summary = root / "benchmarks/results/large/summary.csv"
if not summary.exists():
    raise SystemExit("Missing benchmarks/results/large/summary.csv; run run_large_benchmark.sh first.")
with summary.open(newline="") as f:
    rows = list(csv.DictReader(f))
if len(rows) != 16:
    raise SystemExit(f"Expected 16 rows (8 query shapes x 2 storage types), found {len(rows)}.")
by_key = {(r["query_id"], r["storage"]): r for r in rows}
queries = sorted({r["query_id"] for r in rows})
if len(queries) != 8 or any((q, s) not in by_key for q in queries for s in ("unpartitioned", "hash_partitioned")):
    raise SystemExit("CSV must contain paired unpartitioned and hash_partitioned rows for L01-L08.")
for q in queries:
    if by_key[(q, "unpartitioned")]["row_count"] != by_key[(q, "hash_partitioned")]["row_count"]:
        raise SystemExit(f"Row-count mismatch for {q}.")

lines = [
    "# CP4 Scalability and Partitioning Report", "",
    "## Objective", "",
    "Compare an unpartitioned control relation with an eight-way HASH-partitioned relation using the same deterministic 5x message data.", "",
    "## Partitioning design", "",
    "The experiment partitions by HASH(message_id), not RANGE(sent_at). The source schema uses message_id as a single-column primary key and has self-referential and receipt foreign-key relationships on message_id. PostgreSQL partitioned unique/primary-key constraints must include the partition key; hash partitioning by message_id preserves this single-column key. Range partitioning by sent_at would require a wider primary key and changes to dependent foreign keys, so it is not applied to the existing production table.", "",
    "The SQL creates two separate benchmark relations, messages_unpartitioned_large and messages_hash_partitioned. The production whatsapp.messages table is not replaced or altered. The benchmark data consists of the 120,000 source rows plus four deterministic replicas, giving 600,000 rows per benchmark relation. Replica IDs and self-reply references are remapped, and timestamps are shifted by whole months.", "",
    "## Dataset and storage", "",
    "| Relation | Rows |", "|---|---:|"
]
for storage in ("unpartitioned", "hash_partitioned"):
    lines.append(f"| {storage} | {by_key[(queries[0], storage)]['row_count']} |")
lines += ["", "## Benchmark method", "", "Eight representative read-query shapes (L01-L08) were run three times against each relation using EXPLAIN (ANALYZE, BUFFERS). The complete CSV is `benchmarks/results/large/summary.csv`. Raw plans are saved as `Lxx_unpartitioned.txt` and `Lxx_hash_partitioned.txt` under `benchmarks/results/large/`.", "", "## Results", "", "| Query | Unpartitioned avg (ms) | Hash-partitioned avg (ms) | Partitioned speedup |", "|---|---:|---:|---:|"]
for q in queries:
    u = float(by_key[(q, "unpartitioned")]["avg_ms"])
    h = float(by_key[(q, "hash_partitioned")]["avg_ms"])
    lines.append(f"| {q} | {u:.3f} | {h:.3f} | {u/h:.2f}x |")
lines += ["", "## Interpretation", "", "A speedup above 1.0x means the hash-partitioned copy was faster for that query; below 1.0x means it was slower. HASH(message_id) can prune partitions for predicates on message_id, but it cannot prune partitions for chat_id or sent_at filters. Those query shapes may scan all eight partitions. Do not claim universal partitioning improvement; use the paired timings and plans above.", "", "## Operational considerations and limitations", "", "- The experiment is isolated; the production whatsapp.messages table remains unchanged.", "- The 5x dataset uses repeated source rows with remapped IDs and shifted timestamps. It is suitable for controlled scalability comparison, not a realistic model of future traffic distributions.", "- More partitions add planning, vacuum/analyze, monitoring, and index-maintenance overhead.", "- A production cutover requires a separately reviewed migration, FK validation, ID allocation strategy, and rollback plan.", "- WRITE-heavy workload impact is not represented by the eight read-query shapes; retain separate write benchmarks before recommending production partitioning.", "", "## Reproduction", "", "1. Run `psql -h localhost -p 5433 -U postgres -d whatsapp -v ON_ERROR_STOP=1 -f sql/08_partitioning.sql`.", "2. Run `PGHOST=localhost PGPORT=5433 PGUSER=postgres ./benchmarks/run_large_benchmark.sh whatsapp`.", "3. Run `python3 benchmarks/finalize_large_report.py`.", ""]
report = root / "docs/05_scalability_report.md"
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text("\n".join(lines))
print(f"Wrote {report.relative_to(root)} from {len(rows)} measured benchmark rows.")
