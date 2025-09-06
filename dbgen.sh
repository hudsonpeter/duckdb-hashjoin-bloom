#!/bin/bash

# --- Configurable parameters ---
DUCKDB_BIN="./build/release/duckdb"   # Path to your DuckDB binary
DB_FILE="tpch_sf10.db"                # Output database file
SCALE_FACTOR=10                       # Change this as per expected db size

# --- Check if DuckDB binary exists ---
if [ ! -f "$DUCKDB_BIN" ]; then
  echo "DuckDB binary not found at $DUCKDB_BIN"
  echo "Make sure you've compiled it or adjust the path."
  exit 1
fi

# --- Run DuckDB and generate the data ---
echo "Generating TPC-H data at SF=$SCALE_FACTOR into $DB_FILE..."

"$DUCKDB_BIN" "$DB_FILE" <<EOF
INSTALL tpch;
LOAD tpch;
CALL dbgen(sf=$SCALE_FACTOR);
EOF

echo "Database created: $DB_FILE"
