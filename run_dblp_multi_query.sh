
#!/usr/bin/env bash



TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RESULT_DIR=~/vf3-o/results/dblp_multi_${TIMESTAMP}

mkdir -p "$RESULT_DIR"



VF3P=~/vf3-o/bin/vf3p

DATA_GRAPH=~/slf/dblp_converted/data.graph

QUERY_DIR=~/slf/dblp_converted

CSV_FILE="$RESULT_DIR/dblp_multi.csv"



echo "================================================================"

echo "VF3 OpenMP - DBLP Multi-Query Test"

echo "Testing query variants 1-3 for each size"

echo "1 thread, 30s timeout"

echo "================================================================"



echo "Type,Size,QueryNum,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,Status" > "$CSV_FILE"



test_count=0



# Use the query_sample files which have multiple variants

for size in 4 8 15 25; do

    echo ""

    echo "=== Testing ${size}v queries ==="

    for num in 1 2 3; do

        query="$QUERY_DIR/query_sample_${size}v_${num}.graph"

        

        if [ ! -f "$query" ]; then

            echo "❌ Query not found: $query"

            continue

        fi

        

        test_count=$((test_count + 1))

        echo "[Test ${test_count}] ${size}v query_${num} @ 1t"

        

        /usr/bin/time -v -o "$RESULT_DIR/time.txt" timeout 30s "$VF3P" "$query" "$DATA_GRAPH" -a 2 -t 1 -l 0 -h 3 > "$RESULT_DIR/out.txt" 2>&1

        

        SOL=$(tail -1 "$RESULT_DIR/out.txt" | awk '{print $1}')

        TIME=$(tail -1 "$RESULT_DIR/out.txt" | awk '{print $3}')

        MEM=$(grep "Maximum resident set size" "$RESULT_DIR/time.txt" | awk '{print $NF}')

        CPU=$(grep "Percent of CPU" "$RESULT_DIR/time.txt" | awk '{print $NF}' | tr -d '%')

        

        STATUS="TIMEOUT"

        echo "sample,$size,$num,1,${SOL:-0},${TIME:-30},${MEM:-0},${CPU:-0},$STATUS" >> "$CSV_FILE"

        echo "  → ${SOL:-0} solutions"

    done

done



echo ""

echo "================================================================"

echo "COMPLETE!"

cat "$CSV_FILE"

cp "$CSV_FILE" ~/vf3-o/results/dblp_multi_FINAL.csv

echo "================================================================"

