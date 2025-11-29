#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR=~/vf3-o/results/lj_vf3openmp_${TIMESTAMP}
mkdir -p "$RESULT_DIR"

VF3P=~/vf3-o/bin/vf3p
DATA_GRAPH=~/vf3_test_lj_NEW/livejournal_NO_LABELS.graph
QUERY_DIR=~/vf3_test_lj_NEW
CSV_FILE="$RESULT_DIR/lj_vf3openmp_performance.csv"

echo "================================================================"
echo "VF3 OpenMP - LiveJournal Complete Performance Analysis"
echo "Timeout: 90 seconds per test"
echo "Threads: 1, 8, 16, 32, 64"
echo "Query sizes: 8v, 16v, 32v (dense + sparse)"
echo "Total tests: 30"
echo "================================================================"

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,UserTime_s,SysTime_s,VoluntaryCS,InvoluntaryCS,PageFaults,Status" > "$CSV_FILE"

test_count=0

run_test() {
    local type=$1
    local size=$2
    local threads=$3
    local query="$QUERY_DIR/query_${type}_${size}v_1_NO_LABELS.graph"
    
    if [ ! -f "$query" ]; then
        echo "❌ Query not found: $query"
        echo "$type,$size,$threads,0,0,0,0,0,0,0,0,0,MISSING" >> "$CSV_FILE"
        return
    fi
    
    test_count=$((test_count + 1))
    echo "[Test ${test_count}/30] ${type} ${size}v @ ${threads}t"
    
    /usr/bin/time -v -o "$RESULT_DIR/time_output.txt" \
        timeout 90s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t "$threads" -l 0 -h 3 \
        > "$RESULT_DIR/vf3p_output.txt" 2>&1
    
    EXIT_CODE=$?
    
    OUTPUT=$(cat "$RESULT_DIR/vf3p_output.txt" | tail -1)
    SOLUTIONS=$(echo "$OUTPUT" | awk '{print $1}')
    TOTAL_TIME=$(echo "$OUTPUT" | awk '{print $3}')
    
    MAX_MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    CPU_PERCENT=$(grep "Percent of CPU" "$RESULT_DIR/time_output.txt" | awk '{print $NF}' | tr -d '%')
    USER_TIME=$(grep "User time" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    SYS_TIME=$(grep "System time" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    VOL_CS=$(grep "Voluntary context switches" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    INVOL_CS=$(grep "Involuntary context switches" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time_output.txt" | awk '{print $NF}')
    
    if [ $EXIT_CODE -eq 124 ] || echo "$OUTPUT" | grep -q "TIMEOUT"; then
        STATUS="TIMEOUT"
    elif [ $EXIT_CODE -eq 137 ]; then
        STATUS="OOM"
    else
        STATUS="OK"
    fi
    
    [ -z "$SOLUTIONS" ] && SOLUTIONS=0
    [ -z "$TOTAL_TIME" ] && TOTAL_TIME=0
    [ -z "$MAX_MEM" ] && MAX_MEM=0
    [ -z "$CPU_PERCENT" ] && CPU_PERCENT=0
    [ -z "$USER_TIME" ] && USER_TIME=0
    [ -z "$SYS_TIME" ] && SYS_TIME=0
    [ -z "$VOL_CS" ] && VOL_CS=0
    [ -z "$INVOL_CS" ] && INVOL_CS=0
    [ -z "$PAGE_FAULTS" ] && PAGE_FAULTS=0
    
    echo "$type,$size,$threads,$SOLUTIONS,$TOTAL_TIME,$MAX_MEM,$CPU_PERCENT,$USER_TIME,$SYS_TIME,$VOL_CS,$INVOL_CS,$PAGE_FAULTS,$STATUS" >> "$CSV_FILE"
    echo "  → Solutions: $SOLUTIONS, Mem: $((MAX_MEM/1024/1024))GB, CPU: ${CPU_PERCENT}%"
}

THREADS=(1 8 16 32 64)
SIZES=(8 16 32)

for type in dense sparse; do
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
echo "COMPLETE! Results saved to:"
echo "$CSV_FILE"
echo ""
cat "$CSV_FILE"
echo "================================================================"

cp "$CSV_FILE" ~/vf3-o/results/lj_vf3openmp_FINAL.csv
echo "Also copied to: ~/vf3-o/results/lj_vf3openmp_FINAL.csv"
