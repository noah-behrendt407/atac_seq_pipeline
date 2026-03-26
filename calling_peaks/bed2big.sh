#!/bin/bash
#SBATCH -J bedgraphToBigWig
#SBATCH -o %x-%A_%a.out
#SBATCH -e %x-%A_%a.err
#SBATCH -t 48:00:00
#SBATCH --mem=64GB
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch
#SBATCH --array=0-
#SBATCH --mail-type=END,FAIL

# ------------------
# Environment Setup
# ------------------
set -euo pipefail

# Load local conda env for bedGraphToBigWig
source ~/anaconda3/etc/profile.d/conda.sh
conda activate bedGraphToBigWig

# Load cluster modules
ml BEDTools/2.31.1-GCC-13.3.0
ml SAMtools/1.18-GCC-12.3.0

# ------------------
# Path Variables
# ------------------
i=$SLURM_ARRAY_TASK_ID

# Update these for each project (Maize vs Teosinte)
BASE_DIR="/path/to/project"
INPUT_DIR="${BASE_DIR}/processed_bams"
OUTPUT_DIR="${BASE_DIR}/bigwig_tracks"
CHROM_SIZES="${BASE_DIR}/ref_genome/your_sizes.txt"

mkdir -p "${OUTPUT_DIR}"

# List all sample names here (no extensions)
SAMPLES=(
"sample1"
"sample2"
)

SAMPLE="${SAMPLES[$i]}"
WIN_SIZE=50

# Define File Names
INPUT_1BP="${INPUT_DIR}/${SAMPLE}.clean.tn5.bed"
SLOP_BED="${OUTPUT_DIR}/${SAMPLE}.tn5.${WIN_SIZE}bp.bed"
BG_FILE="${OUTPUT_DIR}/${SAMPLE}.tn5.${WIN_SIZE}bp.bg"
BW_FILE="${OUTPUT_DIR}/${SAMPLE}.tn5.${WIN_SIZE}bp.bw"

# ------------------
# Pipeline Execution
# ------------------

echo "Processing Sample: ${SAMPLE}"

# 1. Expand 1bp cuts to 50bp windows (+/- 25bp)
echo "  Expanding cuts to ${WIN_SIZE}bp windows..."
sort -T "${BASE_DIR}" -k1,1 -k2,2n "${INPUT_1BP}" | \
    bedtools slop -b 25 -i stdin -g "${CHROM_SIZES}" > "${SLOP_BED}"

# 2. Generate BedGraph
echo "  Generating BedGraph..."
bedtools genomecov -i "${SLOP_BED}" -bg -g "${CHROM_SIZES}" > "${BG_FILE}"

# 3. Convert to BigWig
echo "  Converting to BigWig..."
bedGraphToBigWig "${BG_FILE}" "${CHROM_SIZES}" "${BW_FILE}"

# ------------------
# Cleanup
# ------------------
echo "  Cleaning up intermediate files..."
rm "${BG_FILE}"
# Optional: Uncomment the line below to delete the 50bp BED file once BigWig is made
# rm "${SLOP_BED}"

echo "✓ Process Complete for ${SAMPLE}"