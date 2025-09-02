#### ---- Node Induced ---- ####

# QUERY SIZE 64
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=64 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0


# QUERY SIZE 32
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=32 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0

# QUERY SIZE 16
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=16 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0

# QUERY SIZE 8
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=8 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0

# QUERY SIZE 4
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=4 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0

# QUERY SIZE 2
# RUN VF3-P
python3 run_test.py \
    --database_foder="/dataset/DBLP" \
    --dataset_name="DBLP" \
    --query_size=2 \
    --parallel=1 \
    --undirected=1 \
    --edge_induced=0