#!/bin/bash
#SBATCH -e merge_peaks-%J.err
#SBATCH -o merge_peaks-%J.out
#SBATCH -J merge_peaks
#SBATCH -t 02:00:00
#SBATCH --mem=10GB
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -p batch
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu

ml BEDTools/2.31.1-GCC-13.3.0

# Define your input files (The raw peaks from your merged reps)
# Replace these paths with your actual peak file locations
PEAKS=""
OUTPUT_DIR=""

mkdir -p $OUTPUT_DIR

# 1. Use the wildcard (*) to cat ALL files together, then sort and merge
# This treats all peaks from all files as one big dataset to collapse duplicates
cat ${PEAKS}/*.bed | sort -k1,1 -k2,2n | bedtools merge -i stdin > ${OUTPUT_DIR}/_collapsed_peaks.bed


echo "Merge complete. Files saved to $OUTPUT_DIR"
