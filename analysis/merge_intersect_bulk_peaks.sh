#!/bin/bash
#SBATCH -e merge_consensus-%J.err
#SBATCH -o merge_consensus-%J.out
#SBATCH -J merge_consensus
#SBATCH -t 04:00:00
#SBATCH --mem=20GB
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -p batch
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu

ml BEDTools/2.31.1-GCC-13.3.0

# --- User Inputs ---
PEAKS_DIR="/"
OUTPUT_DIR=""
OUTPUT_NAME="Consensus_species_Shared"

mkdir -p "$OUTPUT_DIR"

# Identify the two species files
# Assumes files are named something like TIL11_collapsed.bed and TM_collapsed.bed
FILES=($PEAKS_DIR/*.bed)
FILE_A=${FILES[0]}
FILE_B=${FILES[1]}

echo "Processing Consensus for:"
echo "Species A: $(basename $FILE_A)"
echo "Species B: $(basename $FILE_B)"

# --- Step 1: Create the Union (The "Footprint") ---
# This merges both species together so we have the widest possible coverage
cat "$FILE_A" "$FILE_B" | sort -k1,1 -k2,2n | bedtools merge -i stdin > ${OUTPUT_DIR}/temp_union.bed

# --- Step 2: Double Intersect (The "Filter") ---
# Only keep peaks from the Union that overlap BOTH Species A and Species B
# This ensures it isn't just a peak in one species
bedtools intersect -a ${OUTPUT_DIR}/temp_union.bed -b "$FILE_A" -u | \
bedtools intersect -a stdin -b "$FILE_B" -u > "${OUTPUT_DIR}/${OUTPUT_NAME}_peaks.bed"

# Clean up the temporary file
rm ${OUTPUT_DIR}/temp_union.bed

echo "------------------------------------------------"
echo "Process complete!"
echo "Final Conserved File: ${OUTPUT_DIR}/${OUTPUT_NAME}_peaks.bed"

# --- Quality Check ---
echo "Stats for your Lab Notebook:"
echo "Species A Count: $(wc -l < $FILE_A)"
echo "Species B Count: $(wc -l < $FILE_B)"
echo "Consensus Shared Count: $(wc -l < ${OUTPUT_DIR}/${OUTPUT_NAME}_peaks.bed)"