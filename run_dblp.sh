
#!/usr/bin/env bash

RESULT_DIR=~/vf3-o/results/dblp_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/dblp.csv"

echo "Type,Size,Query,Threads,Solutions,TotalTime_s,MaxMemory_KB,Status" > "$CSV"



for type in sparse dense; do

    for size in 8 16 24 32; do

        for q in 1 2 3; do

            query=~/vf3_test_dblp/query_${type}_${size}v_${q}_NO_LABELS.graph

            [ ! -f "$query" ] && continue

            echo "Testing ${type} ${size}v query_${q}..."

            /usr/bin/time -v -o /tmp/t.txt timeout 30s ~/vf3-o/bin/vf3p "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph -a 2 -t 1 -l 0 -h 3 > /tmp/o.txt 2>&1

            SOL=$(tail -1 /tmp/o.txt | awk '{print $1}')

            TIME=$(tail -1 /tmp/o.txt | awk '{print $3}')

            MEM=$(grep "Maximum resident" /tmp/t.txt | awk '{print $NF}')

            echo "$type,$size,$q,1,${SOL:-0},${TIME:-30},${MEM:-0},TIMEOUT" >> "$CSV"

        done

    done

done

cp "$CSV" ~/vf3-o/results/dblp_FINAL.csv

cat "$CSV"

