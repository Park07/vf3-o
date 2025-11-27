
#!/bin/bash



cd ~/vf3-o/results/enron_omp_*



echo "=== ENRON 2-MINUTE RERUNS (16 tests) ==="



run_test() {

    local type=$1 size=$2 threads=$3

    echo ""

    echo "[$(date +%H:%M:%S)] $type ${size}v @ ${threads}t (120s)..."

    

    /usr/bin/time -v -o /tmp/t.txt timeout --kill-after=5s 120s \

        ~/vf3-o/bin/vf3p ~/vf3_test_enron_NEW/query_${type}_${size}v_1_NO_LABELS.graph \

        ~/vf3_test_enron_NEW/enron_NO_LABELS.graph -a 2 -t $threads -l 0 -h 3 > /tmp/o.txt 2>&1

    

    solutions=$(awk '{print $1}' /tmp/o.txt | tail -1)

    total_time=$(awk '{print $3}' /tmp/o.txt | tail -1)

    max_mem=$(grep "Maximum resident" /tmp/t.txt | awk '{print $6}')

    

    echo "Solutions: ${solutions:-0} | Time: ${total_time:-0}s | Mem: ${max_mem:-0}KB"

    echo "$type,$size,$threads,${solutions:-0},${total_time:-0},${max_mem:-0},120s" >> results_2min.csv

    

    sleep 5

}



echo "Type,Size,Threads,Solutions,TotalTime_s,MaxMemory_KB,Timeout" > results_2min.csv



run_test sparse 16 1

run_test dense 16 1

run_test dense 16 8

run_test dense 16 16

run_test dense 8 32

run_test dense 16 32

run_test dense 16 48

run_test dense 16 64

run_test dense 32 1

run_test sparse 32 8

run_test dense 32 8

run_test dense 32 16

run_test dense 32 32

run_test sparse 32 48

run_test dense 32 48

run_test dense 32 64



echo ""

echo "=== DONE ==="

cat results_2min.csv

