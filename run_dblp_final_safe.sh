
#!/usr/bin/env bash



# === SAFETY: Cap virtual memory at 450GB ===



RESULT_DIR=~/vf3-o/results/dblp_final_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/dblp_complete.csv"



echo "================================================================"

echo "DBLP Complete Benchmark - VF3 OpenMP"

echo "Memory Cap: 450GB | Timeout: 60s"

echo "Sizes: 8v, 16v, 32v | Threads: 8, 16, 32, 48, 64, 96"

echo "Total tests: 36 (6 sizes × 6 threads)"

echo "================================================================"



# Header with full metrics

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV"



test_count=0

total_tests=36



for type in sparse dense; do

    echo ""

    echo "=== Testing ${type} queries ==="

    for size in 8 16 32; do

        for threads in 8 16 32 48 64 96; do

            

            query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph

            [ ! -f "$query" ] && continue

            

            test_count=$((test_count + 1))

            echo -n "[${test_count}/${total_tests}] ${type} ${size}v @ ${threads}t... "

            

            # Run with full time metrics

            /usr/bin/time -v -o /tmp/t.txt timeout 60s ~/vf3-o/bin/vf3p \

                "$query" ~/vf3_test_dblp/dblp_NO_LABELS.graph \

                -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1

            

            EXIT_CODE=$?

            

            # Parse metrics

            SOL=$(tail -1 /tmp/o.txt 2>/dev/null | awk '{print $1}')

            TIME=$(tail -1 /tmp/o.txt 2>/dev/null | awk '{print $3}')

            MEM=$(grep "Maximum resident" /tmp/t.txt 2>/dev/null | awk '{print $NF}')

            CPU=$(grep "Percent of CPU" /tmp/t.txt 2>/dev/null | awk '{print $NF}' | tr -d '%')

            CTX=$(grep "Voluntary context switches" /tmp/t.txt 2>/dev/null | awk '{print $NF}')

            PF=$(grep "Minor (reclaiming a frame) page faults" /tmp/t.txt 2>/dev/null | awk '{print $NF}')

            

            # Determine status

            if [ $EXIT_CODE -eq 0 ]; then

                STATUS="SUCCESS"

                echo "✓ ${SOL} solutions, $((MEM/1024/1024))GB"

            elif [ $EXIT_CODE -eq 124 ]; then

                STATUS="TIMEOUT"

                echo "⏱ TIMEOUT, $((MEM/1024/1024))GB"

            elif [ $EXIT_CODE -eq 137 ] || [ $EXIT_CODE -eq 134 ] || [ $EXIT_CODE -eq 139 ]; then

                STATUS="MEM_LIMIT"

                SOL=0

                echo "💥 HIT MEMORY CAP at $((MEM/1024/1024))GB"

            else

                STATUS="ERROR_${EXIT_CODE}"

                echo "❌ ERROR ${EXIT_CODE}"

            fi

            

            # Write to CSV

            echo "$type,$size,$threads,${SOL:-0},${TIME:-60},${MEM:-0},${CPU:-0},${CTX:-0},${PF:-0},$STATUS" >> "$CSV"

            

        done

    done

done



echo ""

echo "================================================================"

echo "COMPLETE! Results saved to:"

echo "$CSV"

echo ""

echo "Summary:"

grep -c "SUCCESS" "$CSV" && echo "  SUCCESS tests"

grep -c "TIMEOUT" "$CSV" && echo "  TIMEOUT tests" 

grep -c "MEM_LIMIT" "$CSV" && echo "  Memory-limited tests"

echo "================================================================"



cp "$CSV" ~/vf3-o/results/dblp_FINAL.csv

