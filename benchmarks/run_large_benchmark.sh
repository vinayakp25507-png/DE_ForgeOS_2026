#!/usr/bin/env bash
# Compare 5x unpartitioned and 5x hash-partitioned message benchmark copies.
set -euo pipefail
DB="${1:-whatsapp}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/benchmarks/results/large"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.csv"
echo "query_id,storage,row_count,avg_ms,median_ms,min_ms,max_ms,scan_nodes" > "$SUMMARY"

run_one() {
  local id="$1" storage="$2" table="$3" sql="$4"
  local plan t avg median min max nodes
  local -a times=()
  : > "$OUT/${id}_${storage}.txt"
  for run in 1 2 3; do
    plan="$(psql -X -q -A -t -v ON_ERROR_STOP=1 -d "$DB" -c "EXPLAIN (ANALYZE, BUFFERS) $sql")"
    printf '=== %s %s run %s ===\n%s\n' "$id" "$storage" "$run" "$plan" >> "$OUT/${id}_${storage}.txt"
    t="$(printf '%s\n' "$plan" | sed -n 's/.*Execution Time: \([0-9.]*\) ms.*/\1/p' | tail -n 1)"
    [[ -n "$t" ]] || { echo "No execution time parsed for $id $storage" >&2; return 1; }
    times+=("$t")
  done
  local sorted
  sorted="$(printf '%s\n' "${times[@]}" | sort -g)"
  min="$(printf '%s\n' "$sorted" | sed -n '1p')"
  median="$(printf '%s\n' "$sorted" | sed -n '2p')"
  max="$(printf '%s\n' "$sorted" | sed -n '3p')"
  avg="$(printf '%s\n' "${times[@]}" | awk '{s+=$1} END {printf "%.3f",s/NR}')"
  nodes="$(printf '%s\n' "$plan" | grep -Eo '(Parallel )?(Seq Scan|Index Scan|Index Only Scan|Bitmap Heap Scan|Bitmap Index Scan|HashAggregate|GroupAggregate|Sort)' | sort -u | paste -sd'|' - || true)"
  local row_count
  row_count="$(psql -X -q -A -t -d "$DB" -c "SELECT COUNT(*) FROM whatsapp.$table")"
  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' "$id" "$storage" "$row_count" "$avg" "$median" "$min" "$max" "$nodes" >> "$SUMMARY"
  printf '%s %-14s avg %s ms\n' "$id" "$storage" "$avg"
}

for table in messages_unpartitioned_large messages_hash_partitioned; do
  storage="unpartitioned"; [[ "$table" == *hash_partitioned ]] && storage="hash_partitioned"
  run_one L01 "$storage" "$table" "SELECT message_id, sender_id, sent_at, message_type, body FROM whatsapp.$table WHERE chat_id = 22556 ORDER BY sent_at DESC LIMIT 50"
  run_one L02 "$storage" "$table" "SELECT message_type, COUNT(*) FROM whatsapp.$table WHERE sent_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30' AND sent_at < TIMESTAMPTZ '2026-07-01 00:00:00+05:30' GROUP BY message_type ORDER BY message_type"
  run_one L03 "$storage" "$table" "SELECT chat_id, COUNT(*) AS messages FROM whatsapp.$table GROUP BY chat_id ORDER BY messages DESC LIMIT 20"
  run_one L04 "$storage" "$table" "SELECT message_id, sender_id, sent_at FROM whatsapp.$table WHERE reply_to_message_id = 119989 ORDER BY sent_at"
  run_one L05 "$storage" "$table" "SELECT message_type, COUNT(*) FROM whatsapp.$table GROUP BY message_type ORDER BY message_type"
  run_one L06 "$storage" "$table" "SELECT sender_id, COUNT(*) AS messages FROM whatsapp.$table GROUP BY sender_id ORDER BY messages DESC LIMIT 20"
  run_one L07 "$storage" "$table" "SELECT message_id, chat_id, sender_id, sent_at FROM whatsapp.$table ORDER BY message_id DESC OFFSET 100000 LIMIT 25"
  run_one L08 "$storage" "$table" "SELECT chat_id, MAX(sent_at) AS last_message_at FROM whatsapp.$table GROUP BY chat_id ORDER BY last_message_at DESC NULLS LAST LIMIT 100"
done

echo "Saved large-scale benchmark summary and 48 raw plans to $OUT"

# File use case: compare L01-L08 on the two large-data copies and save paired
# plans/timings. DB/ROOT/OUT/SUMMARY configure the run; run_one(id, storage,
# table, sql) gathers plan, times, scan nodes, and row_count for each pair.
