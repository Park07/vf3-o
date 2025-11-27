#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR=~/vf3-o/results/enron_vf3openmp_${TIMESTAMP}
mkdir -p "$RESULT_DIR"

VF3P=~/vf3-o/bin/vf3p
DATA_GRAPH=~/slf/enron_converted/data.graph
QUERY_DIR=~/slf/enron_converted
CSV_FILE="$RESULT_DIR/enron_vf3openmp_performance.csv"

echo "================================================================"
echo "VF3 OpenMP - ENRON Complete Performance Analysis"
echo "Timeout: 25 seconds per test"
echo "Threads: 1, 8, 16, 32, 48, 64"
echo "Query sizes: 8v, 16v, 24v, 32v (dense + sparse)"
echo "Total tests: 48"
echo "Estimated time: ~20 minutes"
echo "================================================================"
echo ""

# CSV header
echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV_FILE"

test_count=0

run_test() {
    local type=$1
    local size=$2
    local threads=$3
    local query="$QUERY_DIR/query_${type}_${size}v_1.graph"
    
    if [ ! -f "$query" ]; then
        echo "❌ Query not found: $query"
        return
    fi
    
    test_count=$((test_count + 1))
    echo "[Test ${test_count}/48] ${type} ${size}v @ ${threads}t"
    
    # Use /usr/bin/time to capture metrics
    /usr/bin/time -v -o "$RESULT_DIR/time_output.txt" \
        timeout 25s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t "$threads" -l 0 -h 3 \
        > "$RESULT_DIR/vf3p_output.txt" 2>&1
    
    EXIT_CODE=$?
    
    # Parse output
    OUTPUT=$(tail -1 "$RESULT_DIR/vf3p_output.txt" 2>/dev/null)
    SOLUTIONS=$(echo "$OUTPUT" | awk '{print $1}')
    TOTAL_TIME=$(echo "$OUTPUT" | awk '{print $3}')
    
    # Parse metrics
    MAX_MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')
    CPU_PERCENT=$(grep "Percent of CPU" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}' | tr -d '%')
    CTX_SWITCHES=$(grep "Voluntary context switches" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')
    PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')
    
    # Status
    if [ $EXIT_CODE -eq 124 ] || echo "$OUTPUT" | grep -q "TIMEOUT"; then
        STATUS="TIMEOUT"
    else
        STATUS="OK"
    fi
    
    # Defaults
    SOLUTIONS=${SOLUTIONS:-0}
    TOTAL_TIME=${TOTAL_TIME:-25}
    MAX_MEM=${MAX_MEM:-0}
    CPU_PERCENT=${CPU_PERCENT:-0}
    CTX_SWITCHES=${CTX_SWITCHES:-0}
    PAGE_FAULTS=${PAGE_FAULTS:-0}
    
    echo "$type,$size,$threads,$SOLUTIONS,$TOTAL_TIME,$MAX_MEM,$CPU_PERCENT,$CTX_SWITCHES,$PAGE_FAULTS,$STATUS" >> "$CSV_FILE"
    echo "  → Solutions: $SOLUTIONS, Time: ${TOTAL_TIME}s, Mem: ${MAX_MEM}KB"
}

# Run all tests
THREADS=(1 8 16 32 48 64)
SIZES=(8 16 24 32)

for type in sparse dense; do
    echo ""
    echo "=== Testing ${type} queries ==="
    for size in "${SIZES[@]}"; do
        for threads in "${THREADS[@]}"; do
            run_test "$type" "$size" "$threads"
        done
    done
done

echo ""
echo "================================================================"
echo "COMPLETE!"
wc -l "$CSV_FILE"
echo "Results: $CSV_FILE"
cp "$CSV_FILE" ~/vf3-o/results/enron_vf3openmp_FINAL.csv
echo "================================================================"
