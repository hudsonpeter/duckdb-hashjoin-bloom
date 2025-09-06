#!/bin/bash

set -e

# --- Config ---
DB_FILE="bloom_test.db"
DUCKDB_BIN="./build/release/duckdb"
MODE="${1:-default}"  # 'bloom' or 'nobloom' or any tag
BLOOM_PRAGMA=""
LOG_BASE="bloom_benchmark"
CUSTOM_SQL_FILE="test_query.sql"

# --- Setup log file ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_BASE}_${MODE}_${TIMESTAMP}.log"
echo "Benchmark Mode: $MODE" > "$LOG_FILE"
echo "Binary: $DUCKDB_BIN" >> "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" >> "$LOG_FILE"
echo "--------------------------" >> "$LOG_FILE"

# --- Write custom SQL test ---
cat > "$CUSTOM_SQL_FILE" <<EOF
$BLOOM_PRAGMA
DROP TABLE IF EXISTS build_table;
DROP TABLE IF EXISTS probe_table;

CREATE TABLE build_table(id INTEGER, value TEXT);
INSERT INTO build_table VALUES (1, 'a'), (2, 'b'), (3, 'c'), (4, 'd'), (5, 'e');

CREATE TABLE probe_table(id INTEGER, description TEXT);
INSERT INTO probe_table VALUES (1, 'first'), (6, 'second');

SELECT * FROM probe_table JOIN build_table USING (id);
EOF

echo "Running custom join test" | tee -a "$LOG_FILE"
{ /usr/bin/time -f "Elapsed: %e sec" \
  $DUCKDB_BIN "$DB_FILE" < "$CUSTOM_SQL_FILE"; } 2>> "$LOG_FILE"
echo "Done custom join test" | tee -a "$LOG_FILE"

rm -f "$CUSTOM_SQL_FILE"

echo -e "\nTest complete. See log: $LOG_FILE"
