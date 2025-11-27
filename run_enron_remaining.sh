#!/bin/bash

cd ~/vf3-o/results/enron_omp_*

# 2-min runs for 0-solution tests
run_test() {
    local type=$1 size=$2 threads=$3 timeout=$4
    
    echo ""
    echo "=== [$(date +%H:%M:%S)] $type ${size}v @ ${threads}t (${timeout}s) ==="
    
    /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s ${timeout}s \
        ~/vf3-o/bin/vf3p ~/vf3_test_enron_NEW/query_${type}_${size}v_1_NO_LABELS.graph \
        ~/vf3_test_enron_NEW/enron_NO_LABELS.graph -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1
    
    exit_code=$?
    solutions=$(awk '{print $1}' /tmp/o.txt | tail -1)
    total_time=$(awk '{print $3}' /tmp/o.txt | tail -1)
    max_mem=$(grep "Maximum resident" /tmp/t.txt | awk '{print $6}')
    cpu=$(grep "Percent of CPU" /tmp/t.txt | grep -oP '\d+')
    ctx=$(grep "Voluntary context" /tmp/t.txt | awk '{print $4}')
    pf=$(grep "Major.*page" /tmp/t.txt | awk '{print $6}')
    
    status="OK"
    [[ $exit_code -eq 124 || $exit_code -eq 137 ]] && status="TIMEOUT"
    [[ $exit_code -eq 134 || "$solutions" == "Aborted" || "$solutions" == "terminate" ]] && status="OOM" && solutions=0
    
    echo "Solutions: ${solutions:-0} | Mem: ${max_mem:-0}KB | Status: $status"
    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},${cpu:-0},${ctx:-0},${pf:-0},$status" >> results.csv
    
    sleep 5
}

echo "=== RE-RUN 0-SOLUTION TESTS (2 min) ==="
run_test sparse 16 1 120
run_test dense 16 1 120
run_test dense 16 8 120
run_test dense 16 16 120

echo "=== REMAINING 8v TESTS (1 min) ==="
for threads in 32 48 64; do
    run_test sparse 8 $threads 60
    run_test dense 8 $threads 60
done

echo "=== REMAINING 16v TESTS (1 min) ==="
for threads in 32 48 64; do
    run_test sparse 16 $threads 60
    run_test dense 16 $threads 60
done

echo "=== 32v TESTS (1 min) ==="
for threads in 1 8 16 32 48 64; do
    run_test sparse 32 $threads 60
    run_test dense 32 $threads 60
done

echo ""
echo "=== DONE ==="
cat results.csv
