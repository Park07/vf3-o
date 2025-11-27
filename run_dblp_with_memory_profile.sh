#!/bin/bash

RESULT_DIR=~/vf3-o/results/dblp_profile_$(date +%Y%m%d_%H%M%S)
mkdir -p "$RESULT_DIR"
cd "$RESULT_DIR"

VF3P=~/vf3-o/bin/vf3p
DBLP_TARGET=~/vf3_test_dblp/dblp_NO_LABELS.graph
DBLP_QUERY_DIR=~/vf3_test_dblp
TIMEOUT_SEC=60

# CSV for final results
echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,Status" > results.csv

# Function to sample memory every second
sample_memory() {
    local pid=$1
    local outfile=$2
    echo "timestamp_s,memory_gb" > "$outfile"
    local start=$(date +%s)
    
    while kill -0 "$pid" 2>/dev/null; do
        local now=$(date +%s)
        local elapsed=$((now - start))
        # Get RSS in KB, convert to GB
        local mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
        local mem_gb=$(echo "scale=2; $mem_kb / 1048576" | bc)
        echo "$elapsed,$mem_gb" >> "$outfile"
        sleep 1
    done
}

run_test() {
    local type=$1
    local size=$2
    local threads=$3
    
    local query="$DBLP_QUERY_DIR/query_${type}_${size}v_1_NO_LABELS.graph"
    local mem_profile="memory_${type}_${size}v_${threads}t.csv"
    
    echo -n "[$(date +%H:%M:%S)] $type ${size}v @ ${threads}t... "
    
    # Start vf3p in background
    timeout --kill-after=5s ${TIMEOUT_SEC}s \
        "$VF3P" "$query" "$DBLP_TARGET" -a 2 -t "$threads" -l 0 -h 3 \
        > output_${type}_${size}_${threads}.txt 2>&1 &
    local vf3_pid=$!
    
    # Start memory sampling in background
    sample_memory "$vf3_pid" "$mem_profile" &
    local sampler_pid=$!
    
    # Wait for vf3p to finish
    wait "$vf3_pid"
    local exit_code=$?
    
    # Stop sampler
    kill "$sampler_pid" 2>/dev/null
    wait "$sampler_pid" 2>/dev/null
    
    # Parse results
    local output=$(cat "output_${type}_${size}_${threads}.txt")
    local solutions=$(echo "$output" | awk 'NF>=1 {print $1}' | tail -1)
    local total_time=$(echo "$output" | awk 'NF>=3 {print $3}' | tail -1)
    local max_mem=$(awk -F',' 'NR>1 {if($2>max)max=$2} END{print max}' "$mem_profile")
    
    # Determine status
    local status="OK"
    if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
        status="TIMEOUT"
    elif [[ -z "$solutions" || "$solutions" == "0" ]]; then
        status="NO_RESULT"
    fi
    
    echo "$solutions solutions, ${max_mem}GB peak, $status"
    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},0,0,$status" >> results.csv
    
    # Cooldown
    sleep 10
}

echo "=== DBLP Memory Profile Benchmark ==="
echo "Results: $RESULT_DIR"
echo ""

# Focused test set
for type in sparse dense; do
    for size in 8 16; do
        for threads in 1 8 16 32 48 64; do
            run_test "$type" "$size" "$threads"
        done
    done
done

echo ""
echo "=== COMPLETE ==="
echo "Memory profiles saved as memory_*.csv"
echo "Plot with: python3 plot_memory.py"
