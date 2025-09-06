// #pragma once

// #include <vector>
// #include <atomic>
// #include <cstddef>
// #include <cstdint>

// namespace duckdb {

// using hash_t = uint64_t;

// class BloomFilter {
// public:
//     BloomFilter(size_t size, size_t num_hashes)
//         : size(size), num_hashes(num_hashes), filter(size) {
//         for (auto &bit : filter) {
//             bit.store(false);
//         }
//     }

//     void Insert(hash_t key) {
//         for (size_t i = 0; i < num_hashes; ++i) {
//             filter[Hash(key, i) % size].store(true, std::memory_order_relaxed);
//         }
//     }

//     bool PossiblyContains(hash_t key) const {
//         for (size_t i = 0; i < num_hashes; ++i) {
//             if (!filter[Hash(key, i) % size].load(std::memory_order_relaxed)) {
//                 return false;
//             }
//         }
//         return true;
//     }

// private:
//     size_t Hash(hash_t key, size_t hash_num) const {
//         // Simple mixing for multiple hash functions
//         hash_t hash1 = key;
//         hash_t hash2 = ~key + (key << 21); // primitive mixing
//         return hash1 + hash_num * hash2;
//     }

//     size_t size;
//     size_t num_hashes;
//     std::vector<std::atomic<bool>> filter;
// };

// } // namespace duckdb


#include "duckdb/common/multilevel_bloom_filter.hpp"
#include <functional>

BloomFilter::BloomFilter(size_t size, size_t num_hashes)
    : size(size), num_hashes(num_hashes), filter(size) {
    for (auto &bit : filter) {
        bit.store(false);
    }
}

void BloomFilter::Insert(const std::string &key) {
    for (size_t i = 0; i < num_hashes; ++i) {
        filter[Hash(key, i) % size].store(true, std::memory_order_relaxed);
    }
}

bool BloomFilter::PossiblyContains(const std::string &key) const {
    for (size_t i = 0; i < num_hashes; ++i) {
        if (!filter[Hash(key, i) % size].load(std::memory_order_relaxed)) {
            return false;
        }
    }
    return true;
}

size_t BloomFilter::Hash(const std::string &key, size_t hash_num) const {
    std::hash<std::string> hash_fn;
    return hash_fn(key + std::to_string(hash_num));
}

MultilevelBloomFilter::MultilevelBloomFilter(size_t num_levels, size_t size, size_t num_hashes, size_t promotion_threshold)
    : promotion_threshold(promotion_threshold), false_positive_count(0), true_positive_count(0) {
    for (size_t i = 0; i < num_levels; ++i) {
        levels.emplace_back(size, num_hashes);
    }
}

void MultilevelBloomFilter::Query(const std::string &key) {
    {
        std::unique_lock<std::mutex> lock(freq_mutex);
        frequency_map[key]++;
    }

    int level = -1;
    {
        std::unique_lock<std::mutex> lock(level_mutex);
        auto it = key_levels.find(key);
        if (it != key_levels.end()) {
            level = it->second;
        }
    }

    if (level == -1) {
        levels[0].Insert(key);
        {
            std::unique_lock<std::mutex> lock(level_mutex);
            key_levels[key] = 0;
        }
        // std::cout << "'" << key << "' is now on level: 0" << std::endl;
    }

    {
        std::unique_lock<std::mutex> lock(freq_mutex);
        if (frequency_map[key] >= promotion_threshold) {
            PromoteKey(key);
        }
    }
}

void MultilevelBloomFilter::PromoteKey(const std::string &key) {
    int current_level;
    {
        std::unique_lock<std::mutex> lock(level_mutex);
        current_level = key_levels[key];
    }

    while (current_level < static_cast<int>(levels.size() - 1)) {
        if (levels[current_level].PossiblyContains(key)) {
            levels[current_level + 1].Insert(key);
            {
                std::unique_lock<std::mutex> lock(level_mutex);
                key_levels[key] = current_level + 1;
            }
            // std::cout << "'" << key << "' is now on level: " << current_level + 1 << std::endl;
            current_level++;
        } else {
            break;
        }
    }

    if (current_level == static_cast<int>(levels.size() - 1)) {
        // std::cout << "'" << key << "' is now on level: " << current_level << " Filled all levels" << std::endl;
    }
}

bool MultilevelBloomFilter::PassesAllLevels(const std::string &key) const {
    for (const auto &level : levels) {
        if (!level.PossiblyContains(key)) {
            false_positive_count.fetch_add(1, std::memory_order_relaxed);
            return false;
        }
    }
    true_positive_count.fetch_add(1, std::memory_order_relaxed);
    return true;
}
