
#!/usr/bin/env bash



TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RESULT_DIR=~/vf3-o/results/enron_dense_only_${TIMESTAMP}

mkdir -p "$RESULT_DIR"



VF3P=~/vf3-o/bin/vf3p

DATA_GRAPH=~/slf/enron_converted/data.graph

QUERY_DIR=~/slf/enron_converted

CSV_FILE="$RESULT_DIR/enron_dense_only.csv"



echo "================================================================"

echo "VF3 OpenMP - ENRON DENSE QUERIES ONLY"

echo "Tests: dense 8v, 16v, 24v, 32v × 6 thread counts = 24 tests"

echo "Timeout: 25s per test"

echo "Memory limit: 440GB"

echo "Estimated time: ~10 minutes"

echo "================================================================"



echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV_FILE"



check_memory() {

    MEM_GB=$(free -g | awk 'NR==2{print $3}')

    if [ "$MEM_GB" -gt 440 ]; then

        echo "❌ MEMORY EXCEEDED: ${MEM_GB}GB"

        pkill -9 vf3p

        exit 1

    fi

}



test_count=0



run_test() {

    local size=$1

    local threads=$2

    local query="$QUERY_DIR/query_dense_${size}v_1.graph"

    

    [ ! -f "$query" ] && return

    

    check_memory

    test_count=$((test_count + 1))

    echo "[Test ${test_count}/24] dense ${size}v @ ${threads}t ($(date +%H:%M:%S))"

    

    /usr/bin/time -v -o "$RESULT_DIR/time_output.txt" timeout 25s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t "$threads" -l 0 -h 3 > "$RESULT_DIR/vf3p_output.txt" 2>&1

    

    OUTPUT=$(tail -1 "$RESULT_DIR/vf3p_output.txt" 2>/dev/null)

    SOLUTIONS=$(echo "$OUTPUT" | awk '{print $1}')

    TOTAL_TIME=$(echo "$OUTPUT" | awk '{print $3}')

    MAX_MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    CPU_PERCENT=$(grep "Percent of CPU" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}' | tr -d '%')

    CTX_SWITCHES=$(grep "Voluntary context switches" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    

    STATUS="TIMEOUT"

    SOLUTIONS=${SOLUTIONS:-0}

    TOTAL_TIME=${TOTAL_TIME:-25}

    MAX_MEM=${MAX_MEM:-0}

    CPU_PERCENT=${CPU_PERCENT:-0}

    CTX_SWITCHES=${CTX_SWITCHES:-0}

    PAGE_FAULTS=${PAGE_FAULTS:-0}

    

    echo "dense,$size,$threads,$SOLUTIONS,$TOTAL_TIME,$MAX_MEM,$CPU_PERCENT,$CTX_SWITCHES,$PAGE_FAULTS,$STATUS" >> "$CSV_FILE"

    echo "  → ${SOLUTIONS} solutions, $((MAX_MEM/1024/1024))GB"

    

    check_memory

}



THREADS=(1 8 16 32 48 64)

SIZES=(8 16 24 32)



for size in "${SIZES[@]}"; do

    echo ""

    echo "=== Testing dense ${size}v ==="

    for threads in "${THREADS[@]}"; do

        run_test "$size" "$threads"

    done

done



echo ""

echo "================================================================"

echo "COMPLETE! 24 dense tests done"

wc -l "$CSV_FILE"

cp "$CSV_FILE" ~/vf3-o/results/enron_dense_FINAL.csv

echo "Saved to: ~/vf3-o/results/enron_dense_FINAL.csv"

echo "================================================================"

