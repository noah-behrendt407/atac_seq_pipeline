#!/bin/bash
#SBATCH -e closest_gene-%J.err
#SBATCH -o closest_gene-%J.out
#SBATCH -J closest_gene
#SBATCH -t 48:00:00
#SBATCH --mem=50GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch

ml BEDTools/2.31.1-GCC-13.3.0

# 1. Define YOUR Absolute Paths
GFF_INPUT=""
GFF_GENES=""
SELECTED_PEAKS_DIR=""
OUTPUT_DIR=""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# 2. Generate and SORT the gene-only GFF (Once)
# This is the "Anchor" for all your ACR assignments
ml BEDTools/2.31.1-GCC-13.3.0

# Generate a CLEAN gene file once
grep -w "gene" "$GFF_INPUT" | sed 's/\r//g' | sort -k1,1 -k4,4n > "$GFF_GENES"

#adjust *bed for files you want to process with this gff3
for PEAK_FILE in "${SELECTED_PEAKS_DIR}"/*.bed
do
    BASE_NAME=$(basename "$PEAK_FILE" .bed)
    RESULT_FILE="${OUTPUT_DIR}/${BASE_NAME}_closest_gene.txt"

    # Process on the fly: Sort peaks, clean potential \r, and find closest gene
    bedtools closest -t first -d \
      -a <(sort -k1,1 -k2,2n "$PEAK_FILE" | sed 's/\r//g') \
      -b "$GFF_GENES" > "$RESULT_FILE"

    echo "Finished $BASE_NAME"
done

echo "------------------------------------------------"
echo "All hand-picked samples in $SELECTED_PEAKS_DIR have been processed."