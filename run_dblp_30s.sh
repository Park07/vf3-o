
#!/usr/bin/env bash

RESULT_DIR=~/vf3-o/results/dblp_30s_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/dblp.csv"



echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV"



echo "Testing: sparse/dense × 8v,16v,32v × 1,8,16,32,48,64t = 36 tests @ 30s"



for type in sparse dense; do

    for size in 8 16 32; do

        for threads in 1 8 16 32 48 64; do

            query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph

            [ ! -f "$query" ] && continue

            

            echo "${type} ${size}v @ ${threads}t..."

            

            /usr/bin/time -v -o /tmp/t.txt timeout 30s ~/vf3-o/bin/vf3p "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1

            

            SOL=$(tail -1 /tmp/o.txt | awk '{print $1}')

            TIME=$(tail -1 /tmp/o.txt | awk '{print $3}')

            MEM=$(grep "Maximum resident" /tmp/t.txt | awk '{print $NF}')

            CPU=$(grep "Percent of CPU" /tmp/t.txt | awk '{print $NF}' | tr -d '%')

            CTX=$(grep "Voluntary context switches" /tmp/t.txt | awk '{print $NF}')

            PF=$(grep "Minor (reclaiming a frame) page faults" /tmp/t.txt | awk '{print $NF}')

            

            echo "$type,$size,$threads,${SOL:-0},${TIME:-30},${MEM:-0},${CPU:-0},${CTX:-0},${PF:-0},TIMEOUT" >> "$CSV"

        done

    done

done



cp "$CSV" ~/vf3-o/results/dblp_FINAL.csv

cat "$CSV"

