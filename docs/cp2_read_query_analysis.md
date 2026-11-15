# CP2 READ Query Performance Analysis

This report analyses the measured baseline execution times of R01-R25.

## Key Performance Findings

| Query | Average Execution Time (ms) | Observation |
|---|---:|---|
| R19 | 19163.481 | Highest execution time; correlated message subqueries |
| R20 | 48.483 | Full message aggregation by hour and type |
| R13 | 23.497 | Sequential scan on messages |
| R14 | 21.993 | Message and chat aggregation |
| R21 | 19.204 | Edited and deleted message aggregation |
| R04 | 18.785 | Message search with sequential scans |
| R15 | 0.036 | Index-only scan on blocked_users |
| R05 | 0.122 | Indexed phone-number lookup |

## Observations

1. R19 is the highest-priority optimization candidate.
2. R20 performs aggregation over the messages table.
3. R13 requires review of its NOT IN subquery and NULL semantics.
4. R04 uses text search and deserves evaluation for suitable indexing.
5. R22 uses deep OFFSET pagination and may benefit from keyset pagination.
6. R05 and R15 demonstrate efficient selective index access.

## Conclusion

The baseline results identify R19 as the dominant performance bottleneck.
Optimization candidates must be tested for result correctness and measured
again before any performance improvement is claimed.

Source: benchmarks/results/baseline/summary.csv
