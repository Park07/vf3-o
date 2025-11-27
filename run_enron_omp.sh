#!/bin/bash

RESULT_DIR=~/vf3-o/results/enron_omp_$(date +%Y%m%d_%H%M%S)
mkdir -p "$RESULT_DIR"
cd "$RESULT_DIR"

echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > results.csv

for type in sparse dense; do
  for size in 8 16; do
    for threads in 1 8 16; do
      echo ""
      echo "============================================"
      echo "[$(date +%H:%M:%S)] $type ${size}v @ ${threads}t"
      echo "============================================"
      
      /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s 60s \
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
      
      echo "Solutions:       ${solutions:-0}"
      echo "TotalTime_s:     ${total_time:-0}"
      echo "MaxMemory_KB:    ${max_mem:-0}"
      echo "CPU_Percent:     ${cpu:-0}%"
      echo "ContextSwitches: ${ctx:-0}"
      echo "PageFaults:      ${pf:-0}"
      echo "Status:          $status"
      
      echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},${cpu:-0},${ctx:-0},${pf:-0},$status" >> results.csv
      
      sleep 5
    done
  done
done

echo ""
echo "============================================"
echo "DONE! Results: $RESULT_DIR/results.csv"
echo "============================================"
cat results.csv
