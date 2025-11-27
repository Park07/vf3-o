#!/bin/bash

cd ~/vf3-o/results

run_test() {
    local type=$1 size=$2 threads=$3
    local query=~/vf3_test_dblp/query_${type}_${size}v_1_NO_LABELS.graph
    local target=~/vf3_test_dblp/dblp_NO_LABELS.graph
    
    echo ""
    echo "============================================"
    echo "[$(date +%H:%M:%S)] $type ${size}v @ ${threads}t"
    echo "============================================"
    
    /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s 60s \
        ~/vf3-o/bin/vf3p "$query" "$target" -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1
    
    local exit_code=$?
    
    echo "=== VF3P OUTPUT ==="
    cat /tmp/o.txt
    
    echo ""
    echo "=== FULL METRICS ==="
    local solutions=$(awk '{print $1}' /tmp/o.txt | tail -1)
    local first_time=$(awk '{print $2}' /tmp/o.txt | tail -1)
    local total_time=$(awk '{print $3}' /tmp/o.txt | tail -1)
    local max_mem=$(grep "Maximum resident" /tmp/t.txt | awk '{print $6}')
    local cpu=$(grep "Percent of CPU" /tmp/t.txt | grep -oP '\d+')
    local vol_ctx=$(grep "Voluntary context" /tmp/t.txt | awk '{print $4}')
    local invol_ctx=$(grep "Involuntary context" /tmp/t.txt | awk '{print $4}')
    local major_pf=$(grep "Major.*page" /tmp/t.txt | awk '{print $6}')
    local minor_pf=$(grep "Minor.*page" /tmp/t.txt | awk '{print $6}')
    local wall_time=$(grep "Elapsed.*wall" /tmp/t.txt | awk '{print $8}')
    local sys_time=$(grep "System time" /tmp/t.txt | awk '{print $4}')
    local user_time=$(grep "User time" /tmp/t.txt | awk '{print $4}')
    
    local status="OK"
    [[ $exit_code -eq 124 || $exit_code -eq 137 ]] && status="TIMEOUT"
    [[ $exit_code -eq 134 ]] && status="OOM"
    [[ -z "$solutions" || "$solutions" == "Aborted" || "$solutions" == "terminate" ]] && status="OOM" && solutions=0
    
    echo "Solutions:           ${solutions:-0}"
    echo "FirstSolution_s:     ${first_time:-0}"
    echo "TotalTime_s:         ${total_time:-0}"
    echo "WallClock:           ${wall_time:-0}"
    echo "UserTime_s:          ${user_time:-0}"
    echo "SystemTime_s:        ${sys_time:-0}"
    echo "MaxMemory_KB:        ${max_mem:-0}"
    echo "CPU_Percent:         ${cpu:-0}%"
    echo "VoluntaryCtxSwitch:  ${vol_ctx:-0}"
    echo "InvoluntaryCtxSwitch:${invol_ctx:-0}"
    echo "MajorPageFaults:     ${major_pf:-0}"
    echo "MinorPageFaults:     ${minor_pf:-0}"
    echo "Status:              $status"
    
    echo ""
    echo "=== CSV LINE ==="
    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},${cpu:-0},${vol_ctx:-0},${major_pf:-0},$status"
    
    # Append to results
    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},${cpu:-0},${vol_ctx:-0},${major_pf:-0},$status" >> results.csv
    
    echo ""
    echo "Cooldown 10s..."
    sleep 10
    
    [[ "$status" == "OOM" ]] && return 1
    return 0
}

echo "=== DENSE TESTS ==="

# Dense 8v
for t in 1 8 16 32; do
    run_test dense 8 $t || break
done

# Dense 16v
for t in 1 16 32; do
    run_test dense 16 $t || break
done

# Dense 32v
for t in 1 16; do
    run_test dense 32 $t || break
done

echo ""
echo "=== ALL DONE ==="
echo "Results in: $(pwd)/results.csv"
