#### ---- Node Induced ---- ####

# QUERY SIZE 64
# RUN VF3-Light
taskset -c 1 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=64 \
    --light=1 \
    --edge_induced=0 &

# RUN VF3
taskset -c 2 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=64 \
    --light=0 \
    --edge_induced=0 &

# QUERY SIZE 32
# RUN VF3-Light
taskset -c 3 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=32 \
    --light=1 \
    --edge_induced=0 &

# RUN VF3
taskset -c 4 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=32 \
    --light=0 \
    --edge_induced=0 &

# QUERY SIZE 16
# RUN VF3-Light
taskset -c 5 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=16 \
    --light=1 \
    --edge_induced=0 &

# RUN VF3
taskset -c 6 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=16 \
    --light=0 \
    --edge_induced=0 &

# QUERY SIZE 8
# RUN VF3-Light
taskset -c 7 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=8 \
    --light=1 \
    --edge_induced=0 &

# RUN VF3
taskset -c 8 python3 run_test.py \
    --database_foder="/dataset/live_journal" \
    --dataset_name="live_journal" \
    --query_size=8 \
    --light=0 \
    --edge_induced=0 &

# # #### ---- Edge Induced ---- ####
# # QUERY SIZE 64
# # RUN VF3-Light
# taskset -c 9 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=64 \
#     --light=1 \
#     --edge_induced=1 &

# # RUN VF3
# taskset -c 10 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=64 \
#     --light=0 \
#     --edge_induced=1 &

# # QUERY SIZE 32
# # RUN VF3-Light
# taskset -c 11 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=32 \
#     --light=1 \
#     --edge_induced=1 &

# # RUN VF3
# taskset -c 12 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=32 \
#     --light=0 \
#     --edge_induced=1 &

# # QUERY SIZE 16
# # RUN VF3-Light
# taskset -c 13 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=16 \
#     --light=1 \
#     --edge_induced=1 &

# # RUN VF3
# taskset -c 14 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=16 \
#     --light=0 \
#     --edge_induced=1 &

# # QUERY SIZE 8
# # RUN VF3-Light
# taskset -c 15 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=8 \
#     --light=1 \
#     --edge_induced=1 &

# # RUN VF3
# taskset -c 16 python3 run_test.py \
#     --database_foder="/dataset/live_journal" \
#     --dataset_name="live_journal" \
#     --query_size=8 \
#     --light=0 \
#     --edge_induced=1