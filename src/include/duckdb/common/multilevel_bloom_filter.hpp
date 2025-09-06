#ifndef MULTILEVEL_BLOOM_FILTER_HPP
#define MULTILEVEL_BLOOM_FILTER_HPP

#include <vector>
#include <unordered_map>
#include <string>
#include <iostream>
#include <atomic>
#include <mutex>

class BloomFilter {
public:
    BloomFilter(size_t size, size_t num_hashes);
    void Insert(const std::string &key);
    bool PossiblyContains(const std::string &key) const;

private:
    size_t Hash(const std::string &key, size_t hash_num) const;

    size_t size;
    size_t num_hashes;
    std::vector<std::atomic<bool>> filter;
};

class MultilevelBloomFilter {
public:
    MultilevelBloomFilter(size_t num_levels, size_t size, size_t num_hashes, size_t promotion_threshold);

    void Query(const std::string &key);
    bool PassesAllLevels(const std::string &key) const;

private:
    void PromoteKey(const std::string &key);

    size_t promotion_threshold;
    std::vector<BloomFilter> levels;
    std::unordered_map<std::string, int> key_levels;
    std::unordered_map<std::string, size_t> frequency_map;

    mutable std::mutex freq_mutex;
    mutable std::mutex level_mutex;

    mutable std::atomic<size_t> false_positive_count;
    mutable std::atomic<size_t> true_positive_count;
};

#endif // MULTILEVEL_BLOOM_FILTER_HPP
