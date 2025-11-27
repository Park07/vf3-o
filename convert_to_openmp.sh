#!/bin/bash

FILE="include/parallel/ParallelMatchingEngine.hpp"

# Step 1: Add OpenMP header after other includes (line 17)
sed -i '17a#include <omp.h>' $FILE

# Step 2: Comment out std::thread and mutex includes (we don't need them)
sed -i 's|^#include <thread>|//#include <thread>|' $FILE
sed -i 's|^#include <mutex>|//#include <mutex>|' $FILE

# Step 3: Replace std::atomic declarations with regular types
# Line 64: std::atomic<bool> once → bool once
sed -i '64s/std::atomic<bool>/bool/' $FILE

# Line 66: std::atomic<int16_t> endThreadCount → int16_t endThreadCount  
sed -i '66s/std::atomic<int16_t>/int16_t/' $FILE

# Line 71: std::atomic<int32_t> statesToBeExplored → int32_t statesToBeExplored
sed -i '71s/std::atomic<int32_t>/int32_t/' $FILE

# Step 4: Replace std::vector<std::thread> pool with int (we don't need it)
sed -i 's/std::vector<std::thread> pool;/int dummy_pool; \/\/ Not needed for OpenMP/' $FILE

echo "Conversion script ready. Now need manual edits for thread creation..."
