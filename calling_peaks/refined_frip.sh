#!/bin/bash
#SBATCH -J refine_frip
#SBATCH -p batch
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH -t 12:00:00
#SBATCH -e /scratch/njb42996/atac/maize/err/refine_%J.err
#SBATCH -o /scratch/njb42996/atac/maize/out/refine_%J.out
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=njb42996@uga.edu

set -e
set -u
set -o pipefail

# Load necessary module
ml BEDTools/2.31.1-GCC-13.3.0

REFINED_DIR=""
PROCESSED_DIR=""
OUTPUT_DIR=""
OUTPUT_FILE="${OUTPUT_DIR}/ refinement_master_stats.tsv"

mkdir -p "$OUTPUT_DIR"

# Create header - Added Peak_Count here
echo -e "Sample\tStringency\tPeak_Count\tTotal_Reads\tReads_In_Peaks\tFRiP" > "$OUTPUT_FILE"

SAMPLES=("B104WT1_AM_S14" "B104WT2_AM_S16")

for SAMPLE in "${SAMPLES[@]}"; do
    echo "Processing FRiP for: ${SAMPLE}"
    
    INPUT_BED="${PROCESSED_DIR}/${SAMPLE}.clean.tn5.bed"
    
    if [ ! -f "$INPUT_BED" ]; then
        echo "Error: $INPUT_BED not found. Skipping."
        continue
    fi

    total_num=$(wc -l < "$INPUT_BED")

    for X in {2..10}; do
        PEAK_FILE="${REFINED_DIR}/${SAMPLE}_${X}xCov_refined_peak.bed"
        
        if [ -f "$PEAK_FILE" ]; then
            # 1. Get Peak Count
            pcount=$(wc -l < "$PEAK_FILE")

            # 2. Get Reads in Peaks (using Tn5 cut sites)
            RiP=$(bedtools intersect -a "$INPUT_BED" -b "$PEAK_FILE" -u | wc -l)
            
            # 3. Calculate FRiP
            frip=$(bc <<< "scale=4; ${RiP}/${total_num}")
            
            # Append everything to the master TSV
            echo -e "${SAMPLE}\t${X}\t${pcount}\t${total_num}\t${RiP}\t${frip}" >> "$OUTPUT_FILE"
            echo "  Done ${X}x: Peaks=${pcount}, FRiP=${frip}"
        else
            echo "  Warning: ${PEAK_FILE} not found."
        fi
    done
done

echo "Finished! Master stats saved to ${OUTPUT_FILE}"