#!/bin/bash

set -e

# --- Config ---
DB_FILE="tpch_sf10.db"
SCALE_FACTOR=10
DUCKDB_BIN="./build/release/duckdb"
QUERY_DIR="./tpch_queries"
LOG_BASE="tpch_benchmark"
MODE="${1:-default}"  # takes 'bloom' or 'nobloom' as arg for labeling

# --- Check if DB exists ---
if [ ! -f "$DB_FILE" ]; then
  echo "Generating TPC-H data at scale factor $SCALE_FACTOR..."
  export LOCAL_EXTENSION_REPO=$PWD/build/release/extension
  $DUCKDB_BIN "$DB_FILE" <<EOF
INSTALL tpch;
LOAD tpch;
CALL dbgen(sf=$SCALE_FACTOR);
EOF
else
  echo "Database $DB_FILE already exists. Skipping dbgen."
fi

# --- Setup log file ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_BASE}_${MODE}_${TIMESTAMP}.log"
echo "Benchmark Mode: $MODE" > "$LOG_FILE"
echo "Binary: $DUCKDB_BIN" >> "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" >> "$LOG_FILE"
echo "--------------------------" >> "$LOG_FILE"

# --- Run queries and time each ---
# for query in "$QUERY_DIR"/q*.sql; do
# running for additional tests created out of tpch queries q23 - q25
for query in "$QUERY_DIR"/q23.sql "$QUERY_DIR"/q24.sql "$QUERY_DIR"/q25.sql; do
  QNAME=$(basename "$query")
  echo -e "\nRunning $QNAME" | tee -a "$LOG_FILE"

  # Time the query execution and redirect both stdout and stderr
  { /usr/bin/time -f "Elapsed: %e sec" \
    $DUCKDB_BIN "$DB_FILE" < "$query"; } 2>> "$LOG_FILE"

  echo "Done $QNAME" | tee -a "$LOG_FILE"
done

echo -e "\nBenchmark complete. See log: $LOG_FILE"
