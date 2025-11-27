
#!/usr/bin/env bash



TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RESULT_DIR=~/vf3-o/results/enron_vf3openmp_continue_${TIMESTAMP}

mkdir -p "$RESULT_DIR"



VF3P=~/vf3-o/bin/vf3p

DATA_GRAPH=~/slf/enron_converted/data.graph

QUERY_DIR=~/slf/enron_converted

CSV_FILE="$RESULT_DIR/enron_vf3openmp_performance.csv"



# Copy existing results

cp ~/vf3-o/results/enron_vf3openmp_*/enron_vf3openmp_performance.csv "$CSV_FILE" 2>/dev/null



if [ ! -f "$CSV_FILE" ]; then

    echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV_FILE"

fi



echo "================================================================"

echo "VF3 OpenMP - ENRON Continue (Tests 14-48)"

echo "Memory limit: 440GB"

echo "================================================================"



check_memory() {

    MEM_GB=$(free -g | awk 'NR==2{print $3}')

    if [ "$MEM_GB" -gt 440 ]; then

        echo "❌ MEMORY EXCEEDED: ${MEM_GB}GB"

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

    

    [ ! -f "$query" ] && return

    

    check_memory

    test_count=$((test_count + 1))

    echo "[Test ${test_count}/48] ${type} ${size}v @ ${threads}t"

    

    # Run with time - all on one line to avoid issues

    /usr/bin/time -v -o "$RESULT_DIR/time_output.txt" timeout 25s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t "$threads" -l 0 -h 3 > "$RESULT_DIR/vf3p_output.txt" 2>&1

    

    OUTPUT=$(tail -1 "$RESULT_DIR/vf3p_output.txt" 2>/dev/null)

    SOLUTIONS=$(echo "$OUTPUT" | awk '{print $1}')

    TOTAL_TIME=$(echo "$OUTPUT" | awk '{print $3}')

    MAX_MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    CPU_PERCENT=$(grep "Percent of CPU" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}' | tr -d '%')

    CTX_SWITCHES=$(grep "Voluntary context switches" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time_output.txt" 2>/dev/null | awk '{print $NF}')

    

    STATUS="TIMEOUT"

    [ "$SOLUTIONS" != "" ] || SOLUTIONS=0

    [ "$TOTAL_TIME" != "" ] || TOTAL_TIME=25

    [ "$MAX_MEM" != "" ] || MAX_MEM=0

    

    echo "$type,$size,$threads,$SOLUTIONS,$TOTAL_TIME,$MAX_MEM,$CPU_PERCENT,$CTX_SWITCHES,$PAGE_FAULTS,$STATUS" >> "$CSV_FILE"

    echo "  → ${SOLUTIONS} solutions, $((MAX_MEM/1024/1024))GB"

}



THREADS=(1 8 16 32 48 64)

SIZES=(8 16 24 32)

CONTINUE=0



for type in sparse dense; do

    for size in "${SIZES[@]}"; do

        for threads in "${THREADS[@]}"; do

            if [ "$type" = "sparse" ] && [ "$size" = "24" ] && [ "$threads" = "8" ]; then

                CONTINUE=1

            fi

            [ $CONTINUE -eq 1 ] && run_test "$type" "$size" "$threads"

        done

    done

done



echo "COMPLETE!"

cp "$CSV_FILE" ~/vf3-o/results/enron_vf3openmp_FINAL.csv

