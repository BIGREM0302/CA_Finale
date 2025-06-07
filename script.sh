#!/usr/bin/env bash
# run_all_caches.sh  —  Sweep all (size,assoc) combinations for L1I/L1D/L2

set -euo pipefail            

sizes=(1 2 4 8 16 32 64 128) # kB

CONF_FILE="gem5_args.conf"
REPORT="report.txt"

: > "${REPORT}" 

for l1i_size   in "${sizes[@]}";  do
  for l1d_size in "${sizes[@]}";  do
    for l2_size in "${sizes[@]}"; do

            GEM5_ARGS="--l1i_size ${l1i_size}kB --l1i_assoc 8 \
              --l1d_size ${l1d_size}kB --l1d_assoc 8 \
              --l2_size  ${l2_size}kB  --l2_assoc  8"

            printf '%s\n' "${GEM5_ARGS}" > "${CONF_FILE}"

            echo "=== Running: ${GEM5_ARGS} ==="
            make g++_final

            make gem5_public ARGS=P5
            
            {   
              echo "----- ${GEM5_ARGS} -----"
              make score_public
              echo                     
            } >> "${REPORT}"

    done
  done
done
