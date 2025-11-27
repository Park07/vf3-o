
#!/usr/bin/env bash

RESULT_DIR=~/vf3-o/results/dblp_cooldown_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/dblp.csv"



echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV"



echo "Testing: sparse/dense × 8v,16v,32v × 1,8,16,32,48,64t = 36 tests @ 60s + 15s cooldown"



test_num=0

for type in sparse dense; do

    for size in 8 16 32; do

        for threads in 1 8 16 32 48 64; do

            query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph

            [ ! -f "$query" ] && continue

            

            test_num=$((test_num + 1))

            echo "[${test_num}/36] ${type} ${size}v @ ${threads}t... ($(date +%H:%M:%S))"

            

            /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s 60s ~/vf3-o/bin/vf3p "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1

            

            SOL=$(tail -1 /tmp/o.txt | awk '{print $1}')

            TIME=$(tail -1 /tmp/o.txt | awk '{print $3}')

            MEM=$(grep "Maximum resident" /tmp/t.txt | awk '{print $NF}')

            CPU=$(grep "Percent of CPU" /tmp/t.txt | awk '{print $NF}' | tr -d '%')

            CTX=$(grep "Voluntary context switches" /tmp/t.txt | awk '{print $NF}')

            PF=$(grep "Minor (reclaiming a frame) page faults" /tmp/t.txt | awk '{print $NF}')

            

            echo "$type,$size,$threads,${SOL:-0},${TIME:-60},${MEM:-0},${CPU:-0},${CTX:-0},${PF:-0},TIMEOUT" >> "$CSV"

            echo "  → ${SOL:-0} solutions, $((${MEM:-0}/1024/1024))GB"

            

            # 15 second cooldown between tests

            echo "  Cooldown 15s..."

            sleep 15

        done

    done

done



cp "$CSV" ~/vf3-o/results/dblp_FINAL.csv

echo "COMPLETE!"

cat "$CSV"

