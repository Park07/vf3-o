#!/usr/bin/env bash
RESULT_DIR=~/vf3-o/results/dblp_multithread_$(date +%Y%m%d_%H%M%S)
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/dblp.csv"
echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV"

echo "Testing DBLP: 8v,16v,32v × sparse,dense × 8,16,32,48,64t = 30 tests"

test_count=0
for type in sparse dense; do
    for size in 8 16 32; do
        for threads in 8 16 32 48 64; do
            query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph
            [ ! -f "$query" ] && continue
            
            test_count=$((test_count + 1))
            echo "[${test_count}/30] ${type} ${size}v @ ${threads}t ($(date +%H:%M:%S))"
            
            /usr/bin/time -v -o /tmp/t.txt timeout 60s ~/vf3-o/bin/vf3p "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1
            
            SOL=$(tail -1 /tmp/o.txt | awk '{print $1}')
            TIME=$(tail -1 /tmp/o.txt | awk '{print $3}')
            MEM=$(grep "Maximum resident" /tmp/t.txt | awk '{print $NF}')
            CPU=$(grep "Percent of CPU" /tmp/t.txt | awk '{print $NF}' | tr -d '%')
            CTX=$(grep "Voluntary context switches" /tmp/t.txt | awk '{print $NF}')
            PF=$(grep "Minor (reclaiming a frame) page faults" /tmp/t.txt | awk '{print $NF}')
            
            echo "$type,$size,$threads,${SOL:-0},${TIME:-60},${MEM:-0},${CPU:-0},${CTX:-0},${PF:-0},TIMEOUT" >> "$CSV"
            echo "  → ${SOL:-0} solutions, $((${MEM:-0}/1024/1024))GB"
        done
    done
done

cp "$CSV" ~/vf3-o/results/dblp_multithread_FINAL.csv
cat "$CSV"
