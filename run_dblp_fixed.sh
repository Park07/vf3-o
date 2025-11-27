#!/usr/bin/env bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR=~/vf3-o/results/dblp_vf3openmp_${TIMESTAMP}
mkdir -p "$RESULT_DIR"

VF3P=~/vf3-o/bin/vf3p
DATA_GRAPH=~/vf3_test_dblp/dblp_NO_LABELS.graph
QUERY_DIR=~/vf3_test_dblp
CSV_FILE="$RESULT_DIR/dblp_vf3openmp.csv"

echo "================================================================"
echo "VF3 OpenMP - DBLP Conservative Test"
echo "1 thread only, ~3 minutes"
echo "================================================================"

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV_FILE"

test_count=0

for type in sparse dense; do
    echo ""
    echo "=== Testing ${type} queries ==="
    for size in 8 16 24 32; do
        query="$QUERY_DIR/query_${type}_${size}v_1_NO_LABELS.graph"
        
        if [ ! -f "$query" ]; then
            echo "❌ Query not found: $query"
            continue
        fi
        
        test_count=$((test_count + 1))
        echo "[Test ${test_count}/8] ${type} ${size}v @ 1t"
        
        /usr/bin/time -v -o "$RESULT_DIR/time.txt" timeout 25s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t 1 -l 0 -h 3 > "$RESULT_DIR/out.txt" 2>&1
        
        SOL=$(tail -1 "$RESULT_DIR/out.txt" | awk '{print $1}')
        TIME=$(tail -1 "$RESULT_DIR/out.txt" | awk '{print $3}')
        MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time.txt" | awk '{print $NF}')
        CPU=$(grep "Percent of CPU" "$RESULT_DIR/time.txt" | awk '{print $NF}' | tr -d '%')
        CTX=$(grep "Voluntary context switches" "$RESULT_DIR/time.txt" | awk '{print $NF}')
        PF=$(grep "Minor (reclaiming a frame) page faults" "$RESULT_DIR/time.txt" | awk '{print $NF}')
        
        echo "$type,$size,1,${SOL:-0},${TIME:-25},${MEM:-0},${CPU:-0},${CTX:-0},${PF:-0},TIMEOUT" >> "$CSV_FILE"
        echo "  → ${SOL:-0} solutions, $((${MEM:-0}/1024/1024))GB"
    done
done

echo ""
echo "================================================================"
echo "COMPLETE!"
cat "$CSV_FILE"
cp "$CSV_FILE" ~/vf3-o/results/dblp_vf3openmp_FINAL.csv
echo "================================================================"
