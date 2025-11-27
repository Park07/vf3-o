
#!/usr/bin/env bash

RESULT_DIR=~/vf3-o/results/dblp_5min_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/dblp.csv"

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,Status" > "$CSV"



for type in sparse dense; do

    for size in 8 16 24 32; do

        query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph

        [ ! -f "$query" ] && continue

        echo "Testing ${type} ${size}v @ 1t (5min timeout)..."

        /usr/bin/time -v -o /tmp/t.txt timeout 300s ~/vf3-o/bin/vf3p "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph -a 2 -t 1 -l 0 -h 3 > /tmp/o.txt 2>&1

        SOL=$(tail -1 /tmp/o.txt | awk '{print $1}')

        TIME=$(tail -1 /tmp/o.txt | awk '{print $3}')

        MEM=$(grep "Maximum resident" /tmp/t.txt | awk '{print $NF}')

        CPU=$(grep "Percent of CPU" /tmp/t.txt | awk '{print $NF}' | tr -d '%')

        echo "$type,$size,1,${SOL:-0},${TIME:-300},${MEM:-0},${CPU:-0},TIMEOUT" >> "$CSV"

    done

done

cp "$CSV" ~/vf3-o/results/dblp_5min_FINAL.csv

cat "$CSV"

