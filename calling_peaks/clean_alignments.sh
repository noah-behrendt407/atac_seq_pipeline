#!/bin/bash
#SBATCH -e clean_alignments-%J.err
#SBATCH -o clean_alignments-%J.out
#SBATCH -J clean_alignments
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH -t 48:00:00
#SBATCH --mem=100GB
#SBATCH -n 1
#SBATCH -c 16
#SBATCH -p batch

# --- PATHS ---
BASE_DIR="/scratch/njb42996/atac"
WORKING_DIR="${BASE_DIR}/"
ALIGNMENTS_DIR="${WORKING_DIR}/alignments"
PROCESSED_DIR="${WORKING_DIR}/processed_bams"
STATS_DIR="${WORKING_DIR}/alignment_stats"
MAPPABLE_BED="${WORKING_DIR}/ "
CHROM_SIZES="${WORKING_DIR}//cleaned_sizes.txt"

# --- SAMPLES ---
SAMPLES=(
    
)

# --- PARAMETERS ---
THREADS=15
MAPQ_THRESHOLD=10
REMOVE_DUPLICATES=true
ATAC_SHIFT=false

# --- MODULES ---
ml SAMtools/1.18-GCC-12.3.0
ml deepTools/3.5.5-gfbf-2023a
ml BEDTools/2.31.1-GCC-13.3.0

mkdir -p "${PROCESSED_DIR}"
mkdir -p "${STATS_DIR}"

for SAMPLE in "${SAMPLES[@]}"; do
    echo "Processing sample: ${SAMPLE}"
    
    INPUT_SAM="${ALIGNMENTS_DIR}/${SAMPLE}.sam"
    [ ! -f "${INPUT_SAM}" ] && { echo "ERROR: SAM not found"; continue; }
    
    # File Definitions
    RAW_BAM="${PROCESSED_DIR}/${SAMPLE}.bam"
    UNIQUE_FILTERED_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual.bam"
    SORTED_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual_sorted.bam"
    FIXMATE_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual_sorted_fixmate.bam"
    POSITION_SORTED_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual_sorted_fixmate_positionSort.bam"
    MTCP_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual_sorted_fixmate_positionSort_noMtCp.bam"
    DEDUP_BAM="${PROCESSED_DIR}/${SAMPLE}_highQual_noDups.bam"
    MAPPABLE_BAM="${PROCESSED_DIR}/${SAMPLE}.clean.bam"
    CLEAN_BED="${PROCESSED_DIR}/${SAMPLE}.clean.bed"
    TN5_BED="${PROCESSED_DIR}/${SAMPLE}.clean.tn5.bed"

    # 1. Convert and Raw Stats
    samtools view -@ ${THREADS} -b -h "${INPUT_SAM}" > "${RAW_BAM}"
    samtools stats -@ ${THREADS} "${RAW_BAM}" > "${STATS_DIR}/${SAMPLE}_RAW_stats.txt"

    # 2. Filter MQ
    samtools view -@ ${THREADS} -h -b -f 3 -q ${MAPQ_THRESHOLD} -o "${UNIQUE_FILTERED_BAM}" "${RAW_BAM}"
    
    # 3. Fixmate & Sort
    samtools sort -@ ${THREADS} -n -o "${SORTED_BAM}" "${UNIQUE_FILTERED_BAM}"
    samtools fixmate -@ ${THREADS} -m "${SORTED_BAM}" "${FIXMATE_BAM}"
    samtools sort -@ ${THREADS} -o "${POSITION_SORTED_BAM}" "${FIXMATE_BAM}"
    
    mv "${POSITION_SORTED_BAM}" "${MTCP_BAM}"
    samtools index "${MTCP_BAM}"

    # 4. Dedup
    if [ "${REMOVE_DUPLICATES}" = true ]; then
        samtools markdup -@ ${THREADS} -r -s "${MTCP_BAM}" "${DEDUP_BAM}"
        PROCESSING_BAM="${DEDUP_BAM}"
    else
        PROCESSING_BAM="${MTCP_BAM}"
    fi

    # 5. Mappable Regions Filter
    bedtools intersect -abam "${PROCESSING_BAM}" -b "${MAPPABLE_BED}" > "${MAPPABLE_BAM}"
    FINAL_PROCESSED_BAM="${MAPPABLE_BAM}"
    samtools index "${FINAL_PROCESSED_BAM}"

    # 6. Final Stats (Now correctly inside the loop)
    echo "  Generating Final Cleaned Alignment Stats"
    samtools stats -@ ${THREADS} "${FINAL_PROCESSED_BAM}" > "${STATS_DIR}/${SAMPLE}_FINAL_stats.txt"
    
    # 7. 1bp Bed Generation
    bedtools bamtobed -i "${FINAL_PROCESSED_BAM}" > "${CLEAN_BED}"
    awk 'BEGIN {OFS = "\t"} {if ($6 == "+") print $1, $2, $2 + 1; else print $1, $3 - 1, $3}' \
    "${CLEAN_BED}" > "${TN5_BED}"
    
    # 8. Cleanup
    rm -f "${RAW_BAM}" "${UNIQUE_FILTERED_BAM}" "${SORTED_BAM}" "${FIXMATE_BAM}" "${MTCP_BAM}"
    echo "  ✓ Finished processing sample: ${SAMPLE}"
done

echo "All samples processed!"