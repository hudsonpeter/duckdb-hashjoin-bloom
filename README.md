# CS550 - Advanced Data Systems  
## Project: Hash Join Optimization with Bloom Filter  

## Overview
This project enhances **DuckDB** by integrating a **multi-level Bloom filter** into the **Hash Join operator**.  
The optimization improves join performance on large datasets by reducing unnecessary data scans during the probe phase, particularly in highly selective queries.  

Developed as part of **CSCI-550 (Advanced Database Systems, USC)**.  

---

## 📂 Project Structure
```
submission/
│
├── dbgen.sh              # Script to generate TPC-H dataset
├── multi_test.sh         # Batch test script for running multiple join queries
├── simple_test.sh        # Basic test with custom small tables (build + probe)
├── tpch_bm_bf.sh         # Benchmark script for TPC-H queries with/without Bloom filter
│
├── src/                  # Source code modifications
│   ├── common/
│   │   ├── CMakeLists.txt
│   │   └── multilevel_bloom_filter.cpp
│   ├── execution/
│   │   └── operator/
│   │       └── join/
│   │           └── physical_hash_join.cpp
│   └── include/
│       └── duckdb/
│           └── common/
│               ├── common.hpp
│               └── multilevel_bloom_filter.hpp
│
└── tpch_queries/         # TPC-H SQL queries for benchmarking
    ├── q01.sql
    ├── q02.sql
    ├── ...
    └── q25.sql
```

---

## ⚙️ Build Instructions

1. Clone DuckDB and copy modified files into the appropriate directories:
   ```bash
   git clone https://github.com/duckdb/duckdb.git
   cd duckdb
   ```

2. Enable the Bloom filter flag in `physical_hash_join.cpp`:
   ```cpp
   bool enable_multilevel_bloom_filter = true;
   ```

3. Build DuckDB in release mode:
   ```bash
   make release
   ```

---

## ▶️ Running Tests

### 1. Generate TPC-H Dataset
```bash
./dbgen.sh
```

### 2. Run Simple Test (build + probe)
```bash
./simple_test.sh
```

### 3. Run TPC-H Benchmark
With Bloom filter enabled:
```bash
./tpch_bm_bf.sh bloom
```
Without Bloom filter:
```bash
./tpch_bm_bf.sh nobloom
```

### 4. Run Multiple Queries
```bash
./multi_test.sh bloom
./multi_test.sh nobloom
```

---

## 📊 Results
- Reduced probe overhead for selective joins.  
- **Performance gains** observed on TPC-H queries with high selectivity.  
- Multi-level Bloom filters yielded **fewer false positives** than single-level.  

---

## 📝 Notes
- Controlled by the `enable_multilevel_bloom_filter` flag in `physical_hash_join.cpp`.  
- Falls back to the standard Hash Join implementation when disabled.  

---

## 📜 Attribution
This project builds on the official [DuckDB](https://duckdb.org/) engine.  
Enhancements were developed for **educational purposes** under the USC **CSCI-550 course**.  
