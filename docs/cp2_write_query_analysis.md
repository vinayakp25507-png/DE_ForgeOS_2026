# CP2 WRITE Query Performance Analysis

This report analyses the measured baseline execution times of W01-W05.

## Baseline Results

| Query | Average Execution Time (ms) | Observation |
|---|---:|---|
| W01 | 0.994 | Single message insertion |
| W02 | 5.254 | Read receipt update |
| W03 | 0.120 | Single message deletion update |
| W04 | 25.622 | Insertion of 5000 delivery receipts |
| W05 | 0.214 | Group membership update |

## Performance Observations

1. W04 has the highest execution time because it inserts 5000 receipt records.
2. W02 scans messages and updates matching receipt records.
3. W01 inserts a single text message using database defaults.
4. W03 uses the message primary key to locate the target record.
5. W05 uses the composite chat membership primary key.

## Transaction Safety

All five write queries were benchmarked inside transactions followed by
ROLLBACK. Their test changes were therefore not permanently committed.

## Conclusion

W04 is the most expensive write operation in the measured workload.
Further optimization should consider bulk insertion efficiency and index
maintenance overhead.

Source: benchmarks/results/baseline/summary.csv
