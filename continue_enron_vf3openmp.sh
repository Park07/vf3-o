
#!/bin/bash



TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RESULT_DIR=~/vf3-o/results/enron_vf3openmp_continue_${TIMESTAMP}

mkdir -p "$RESULT_DIR"



VF3P=~/vf3-o/bin/vf3p

DATA_GRAPH=~/slf/enron_converted/data.graph

QUERY_DIR=~/slf/enron_converted

CSV_FILE="$RESULT_DIR/enron_vf3openmp_performance.csv"



# Copy existing results

cp ~/vf3-o/results/enron_vf3openmp_*/enron_vf3openmp_performance.csv "$CSV_FILE" 2>/dev/null



# If no existing file, create header

if [ ! -f "$CSV_FILE" ]; then

    echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV_FILE"

fi



echo "================================================================"

echo "VF3 OpenMP - ENRON Continue (Tests 14-48)"

echo "Starting from: sparse 24v @ 8t"

echo "Memory limit: 440GB (auto-terminate if exceeded)"

echo "================================================================"



check_memory() {

    MEM_GB=$(free -g | awk 'NR==2{print $3}')

    if [ "$MEM_GB" -gt 440 ]; then

        echo "❌ MEMORY LIMIT EXCEEDED: ${MEM_GB}GB > 440GB"

        echo "Terminating to prevent OOM..."

        pkill -9 vf3p

        exit 1

    fi

}



test_count=13



run_test() {

    local type=$1

    local size=$2

    local threads=$3

    local query="$QUERY_DIR/query_${type}_${size}v_1.graph"

    

    if [ ! -f "$query" ]; then

        return

    fi

    

    # Check memory before test

    check_memory

    

    test_count=$((test_count + 1))

    echo "[Test ${test_count}/48] ${type} ${size}v @ ${threads}t ($(date +%H:%M:%S))"

    

    /usr/bin/time -v -o "$RESULT_DIR/time_output.txt" \

        timeout 25s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t "$threads" -l 0 -h 3 \

        > "$RESULT_DIR/vf3p_output.txt" 2>&1

    

    EXIT_CODE=$?

    

    OUTPUT=$(tail -1 "$RESULT_DIR/vf3p_output.txt" 2>/dev/null)

    SOLUTIONS=$(echo "$OUTPUT" | awk '{print $1}')

    TOTAL_TIME=$(echo "$OUTPUT" | awk '{print $3}')

    

    MAX_MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    CPU_PERCENT=$(grep "Percent of CPU" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}' | tr -d '%')

    CTX_SWITCHES=$(grep "Voluntary context switches" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    

    if [ $EXIT_CODE -eq 124 ] || echo "$OUTPUT" | grep -q "TIMEOUT"; then

        STATUS="TIMEOUT"

    else

        STATUS="OK"

    fi

    

    SOLUTIONS=${SOLUTIONS:-0}

    TOTAL_TIME=${TOTAL_TIME:-25}

    MAX_MEM=${MAX_MEM:-0}

    CPU_PERCENT=${CPU_PERCENT:-0}

    CTX_SWITCHES=${CTX_SWITCHES:-0}

    PAGE_FAULTS=${PAGE_FAULTS:-0}

    

    echo "$type,$size,$threads,$SOLUTIONS,$TOTAL_TIME,$MAX_MEM,$CPU_PERCENT,$CTX_SWITCHES,$PAGE_FAULTS,$STATUS" >> "$CSV_FILE"

    echo "  → Solutions: $SOLUTIONS, Mem: $((MAX_MEM/1024/1024))GB"

    

    # Check memory after test

    check_memory

}



THREADS=(1 8 16 32 48 64)

SIZES=(8 16 24 32)



# Start from sparse 24v @ 8t (test 14)

CONTINUE=0

for type in sparse dense; do

    for size in "${SIZES[@]}"; do

        for threads in "${THREADS[@]}"; do

            # Skip until we reach sparse 24v @ 8t

            if [ "$type" = "sparse" ] && [ "$size" = "24" ] && [ "$threads" = "8" ]; then

                CONTINUE=1

            fi

            

            if [ $CONTINUE -eq 1 ]; then

                run_test "$type" "$size" "$threads"

            fi

        done

    done

done



echo ""

echo "================================================================"

echo "COMPLETE!"

wc -l "$CSV_FILE"

cp "$CSV_FILE" ~/vf3-o/results/enron_vf3openmp_FINAL.csv

echo "================================================================"

