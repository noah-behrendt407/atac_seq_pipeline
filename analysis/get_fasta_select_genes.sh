#!/bin/bash
#SBATCH -e M_closest_fasta-%J.err
#SBATCH -o M_closest_fasta-%J.out
#SBATCH -J M-closest_fa
#SBATCH -t 02:00:00
#SBATCH --mem=10GB
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -p batch

ml BEDTools/2.31.1-GCC-13.3.0

ref=""
CLOSEST_DIR=""
FA_DIR=""
ID_LIST=""

mkdir -p "${FA_DIR}"

# 1. Look for your B104 "Closest" result file
for file in "${CLOSEST_DIR}"/Consensus_*.txt; do
    # Get a unique base name (e.g., Consensus_Teosinte_Shared_peaks)
    base=$(basename "$file" .txt)
    echo "Processing $base..."

    # STEP A: Create a UNIQUE temp BED file for this specific run
    # This prevents Maize and Teosinte from fighting over the same temp file
    grep -Fwf "$ID_LIST" "$file" | awk '{print $1"\t"$2"\t"$3}' > "${FA_DIR}/temp_${base}.bed"

    # STEP B: Run getfasta using the UNIQUE temp file and a UNIQUE output name
    echo "Extracting FASTA sequences for $base..."
    bedtools getfasta -fi "$ref" -bed "${FA_DIR}/temp_${base}.bed" -fo "${FA_DIR}/sequences_${base}_20_peaks.fa"

    # Clean up the specific temp file
    rm "${FA_DIR}/temp_${base}.bed"
done