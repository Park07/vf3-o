#!/bin/bash

RESULT_DIR=~/vf3-o/results/dblp_focused_$(date +%Y%m%d_%H%M%S)
mkdir -p "$RESULT_DIR"
cd "$RESULT_DIR"

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > results.csv

run_test() {
    local type=$1 size=$2 threads=$3
    local query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph
    local target=~/vf3_test_dblp/dblp_NO_LABELS.graph
    
    echo -n "[$(date +%H:%M:%S)] $type ${size}v @ ${threads}t... "
    
    /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s 60s \
        ~/vf3-o/bin/vf3p "$query" "$target" -a 2 -t $threads -l 0 -h 3 \
        > /tmp/o.txt 2>&1
    
    local exit_code=$?
    local solutions=$(awk '{print $1}' /tmp/o.txt | tail -1)
    local total_time=$(awk '{print $3}' /tmp/o.txt | tail -1)
    local max_mem=$(grep "Maximum resident" /tmp/t.txt | awk '{print $6}')
    local cpu=$(grep "Percent of CPU" /tmp/t.txt | grep -oP '\d+')
    local ctx=$(grep "Voluntary context" /tmp/t.txt | awk '{print $4}')
    local pf=$(grep "Major.*page" /tmp/t.txt | awk '{print $6}')
    
    local status="OK"
    [[ $exit_code -eq 132 || $exit_code -eq 137 ]] && status="TIMEOUT"
    [[ $exit_code -eq 134 ]] && status="OOM"
    [[ -z "$solutions" || "$solutions" == "Aborted" || "$solutions" == "terminate" ]] && status="OOM" && solutions=0
    
    echo "$solutions solutions, ${max_mem:-0}KB, $status"
    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},${cpu:-0},${ctx:-0},${pf:-0},$status" >> results.csv
    
    sleep 10
    
    # Return 1 if OOM (to skip higher threads)
    [[ "$status" == "OOM" ]] && return 1
    return 0
}

echo "=== FOCUSED DBLP BENCHMARK ==="

# 8v - we know 48+ fails
for t in 1 8 16 32; do
    run_test sparse 8 $t
done

# 16v - stop if OOM
for t in 1 16 32; do
    run_test sparse 16 $t || break
done

# 32v - stop if OOM  
for t in 1 16; do
    run_test sparse 32 $t || break
done

# Dense (usually easier)
for t in 1 8 16 32; do
    run_test dense 8 $t || break
done

echo ""
echo "=== DONE ==="
cat results.csv
