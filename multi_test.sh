#!/bin/bash

set -e

# === Config ===
DB_FILE="tpch_sf10.db"
DUCKDB_BIN="./build/release/duckdb"
TEST_DIR="./join_tests"
LOG_DIR="./logs"
MODE="${1:-default}"  # 'bloom' or 'nobloom'

mkdir -p "$TEST_DIR" "$LOG_DIR"

# === Create DB if needed ===
if [ ! -f "$DB_FILE" ]; then
  echo "Creating TPCH DB..."
  $DUCKDB_BIN "$DB_FILE" <<'EOF'
INSTALL tpch;
LOAD tpch;
CALL dbgen(sf=10);
EOF
fi

cat > "$TEST_DIR/test_01_basic.sql" <<'EOF'
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
LIMIT 10;
EOF

cat > "$TEST_DIR/test_02_nomatch.sql" <<'EOF'
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey + 1000000;
EOF

cat > "$TEST_DIR/test_03_onetomany.sql" <<'EOF'
SELECT c.c_custkey, o.o_orderkey
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
WHERE c.c_custkey = 1;
EOF

cat > "$TEST_DIR/test_04_reverse.sql" <<'EOF'
SELECT *
FROM customer c
JOIN orders o ON o.o_custkey = c.c_custkey;
EOF

cat > "$TEST_DIR/test_05_filtering.sql" <<'EOF'
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_custkey > 1000000;
EOF

cat > "$TEST_DIR/test_06_large.sql" <<'EOF'
SELECT *
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE l.l_orderkey < 10000;
EOF

cat > "$TEST_DIR/test_07_chained.sql" <<'EOF'
SELECT *
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LIMIT 10;
EOF

cat > "$TEST_DIR/test_08_falsepos.sql" <<'EOF'
SELECT *
FROM (
  SELECT 999999 AS o_custkey
  UNION ALL
  SELECT 888888
) o
JOIN customer c ON o.o_custkey = c.c_custkey;
EOF

cat > "$TEST_DIR/test_10_empty.sql" <<'EOF'
SELECT *
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 1 = 0;
EOF

# === Run and time each test ===

TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/join_test_${MODE}_${TS}.log"

echo "Running join tests - Mode: $MODE" > "$LOG_FILE"

for file in "$TEST_DIR"/test_*.sql; do
  name=$(basename "$file")
  echo "" >> "$LOG_FILE"
  echo "Running $name..." | tee -a "$LOG_FILE"
  
  { /usr/bin/time -f "Time: %e sec" \
    $DUCKDB_BIN "$DB_FILE" < "$file"; } >> "$LOG_FILE" 2>&1

  echo "Done $name" | tee -a "$LOG_FILE"
done

echo "All tests completed. Log: $LOG_FILE"
