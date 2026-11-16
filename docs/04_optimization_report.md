# CP3 Query Optimization Report

## 1. Executive summary

- Workload: 25 READ queries (R01-R25) and 5 WRITE queries (W01-W05).
- Benchmark method: EXPLAIN (ANALYZE, BUFFERS), three runs per query.
- Database: PostgreSQL 18.6, schema whatsapp, session timezone Asia/Kolkata.
- Queries faster than CP2 baseline: 20/30.
- Queries slower than CP2 baseline: 10/30.
- All write benchmarks use BEGIN/ROLLBACK in the benchmark runner.

## 2. Before / after query timings

| Query | Type | Baseline avg (ms) | Optimized avg (ms) | Speedup | Change |
|---|---|---:|---:|---:|---:|
| R01 | READ | 19.603 | 0.182 | 107.71x | +99.1% |
| R02 | READ | 3.590 | 0.257 | 13.97x | +92.8% |
| R03 | READ | 12.262 | 0.438 | 28.00x | +96.4% |
| R04 | READ | 18.785 | 8.131 | 2.31x | +56.7% |
| R05 | READ | 0.122 | 0.034 | 3.59x | +72.1% |
| R06 | READ | 3.208 | 3.627 | 0.88x | -13.1% |
| R07 | READ | 1.368 | 0.516 | 2.65x | +62.3% |
| R08 | READ | 14.427 | 19.486 | 0.74x | -35.1% |
| R09 | READ | 10.255 | 15.344 | 0.67x | -49.6% |
| R10 | READ | 8.126 | 2.255 | 3.60x | +72.2% |
| R11 | READ | 5.622 | 3.633 | 1.55x | +35.4% |
| R12 | READ | 6.235 | 6.650 | 0.94x | -6.7% |
| R13 | READ | 23.497 | 7.732 | 3.04x | +67.1% |
| R14 | READ | 21.993 | 3.501 | 6.28x | +84.1% |
| R15 | READ | 0.036 | 0.029 | 1.24x | +19.4% |
| R16 | READ | 0.442 | 0.352 | 1.26x | +20.4% |
| R17 | READ | 17.255 | 19.911 | 0.87x | -15.4% |
| R18 | READ | 16.294 | 15.405 | 1.06x | +5.5% |
| R19 | READ | 19163.481 | 15.936 | 1202.53x | +99.9% |
| R20 | READ | 48.483 | 50.738 | 0.96x | -4.7% |
| R21 | READ | 19.204 | 12.673 | 1.52x | +34.0% |
| R22 | READ | 13.807 | 9.016 | 1.53x | +34.7% |
| R23 | READ | 4.184 | 2.322 | 1.80x | +44.5% |
| R24 | READ | 8.564 | 9.924 | 0.86x | -15.9% |
| R25 | READ | 0.131 | 0.066 | 1.98x | +49.6% |
| W01 | WRITE | 0.994 | 0.681 | 1.46x | +31.5% |
| W02 | WRITE | 5.254 | 0.594 | 8.85x | +88.7% |
| W03 | WRITE | 0.120 | 0.137 | 0.88x | -14.2% |
| W04 | WRITE | 25.622 | 32.119 | 0.80x | -25.4% |
| W05 | WRITE | 0.214 | 0.224 | 0.96x | -4.7% |

## 3. Largest improvements

| Query | Baseline (ms) | Optimized (ms) | Speedup |
|---|---:|---:|---:|
| R19 | 19163.481 | 15.936 | 1202.53x |
| R01 | 19.603 | 0.182 | 107.71x |
| R03 | 12.262 | 0.438 | 28.00x |
| R02 | 3.590 | 0.257 | 13.97x |
| W02 | 5.254 | 0.594 | 8.85x |

## 4. Largest regressions

| Query | Baseline (ms) | Optimized (ms) | Change |
|---|---:|---:|---:|
| R09 | 10.255 | 15.344 | -49.6% |
| R08 | 14.427 | 19.486 | -35.1% |
| W04 | 25.622 | 32.119 | -25.4% |
| R24 | 8.564 | 9.924 | -15.9% |
| R17 | 17.255 | 19.911 | -15.4% |

## 5. Plan evidence

Top five improvements have baseline and optimized raw plans in the following files:
- R19: `benchmarks/results/baseline/R19.txt` and `benchmarks/results/optimized/R19.txt`
- R01: `benchmarks/results/baseline/R01.txt` and `benchmarks/results/optimized/R01.txt`
- R03: `benchmarks/results/baseline/R03.txt` and `benchmarks/results/optimized/R03.txt`
- R02: `benchmarks/results/baseline/R02.txt` and `benchmarks/results/optimized/R02.txt`
- W02: `benchmarks/results/baseline/W02.txt` and `benchmarks/results/optimized/W02.txt`

All 30 optimized raw plans are saved under `benchmarks/results/optimized/`. The summary is `benchmarks/results/optimized/summary.csv`.

## 6. Index design and storage

| Index | Workload | Size | Benchmark index scans |
|---|---|---:|---:|
| idx_chat_members_user_active_chat | R01, W05 | 3048 kB | 12 |
| idx_messages_chat_sent_desc | R01, R02, R13, W02 | 3720 kB | 90 |
| idx_receipts_unread_user_message | R03, W02 | 4672 kB | 12 |
| idx_receipts_undelivered_message | R08 | 272 kB | 12 |
| idx_messages_sent_at | R10, R14, R17 | 2656 kB | 50 |
| idx_calls_missed_started_chat | R11 | 216 kB | 24 |
| idx_devices_web_desktop_activity | R23 | 280 kB | 6 |

Total database index storage at audit time: **40 MB**. The seven CP3 indexes above use approximately 14.5 MB. Two experimental indexes without observed scans (message-body trigram and read-receipt covering index) were removed. Usage counters are cumulative database statistics, not isolated per-query measurements.

## 7. Correctness verification

- R19: original and optimized queries returned 3000 rows each; both EXCEPT ALL difference counts were zero.
- R10: original and rewritten date-range queries returned 30 daily rows each; both EXCEPT ALL difference counts were zero.
- R13: original NOT IN returned zero unanswered questions while NOT EXISTS returned seven. There were 105090 NULL reply references and nine candidate questions. This is a deliberate correctness fix; output is not equivalent to the NULL-affected original.

## 8. Regression and limitations

- R20 was not rewritten in the final workload. A test expression index was removed because the planner did not choose it under normal settings and forced index scan was slower than the normal plan.
- Queries slower than baseline in the final benchmark: R06, R08, R09, R12, R17, R20, R24, W03, W04 and W05. R18 improved from 16.294 ms to 15.405 ms (approximately 5.5% faster).
- W04 inserts 5000 receipt rows. Its measured write overhead increased from the baseline; added indexes can increase write costs.
- A benchmark timing is workload- and cache-dependent. Compare plans and repeated runs, not execution time alone.

## 9. Deliverable map

- `sql/05_indexes.sql` — workload-driven index definitions.
- `sql/06_optimized_queries.sql` — optimized workload; R10, R13 and R19 changed.
- `benchmarks/results/optimized/summary.csv` — final three-run averages and ranges.
- `benchmarks/results/optimized/` — raw execution plans for all queries.
- `docs/04_optimization_report.md` — this report.

## 10. Submission status

This report and its evidence files are generated locally. No Git commit or push has been performed. AP application SQL documentation already exists at `ForgeOS_AP_2026/dbms/04_queries.sql`; it should be reviewed separately before submission.
