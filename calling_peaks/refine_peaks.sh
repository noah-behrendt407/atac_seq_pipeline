#!/bin/bash
#SBATCH -J refine_peaks
#SBATCH -p batch
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=100G
#SBATCH -t 24:00:00
#SBATCH -e refine_%J.err
#SBATCH -o refine_%J.out
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=njb42996@uga.edu

set -e
set -u
set -o pipefail

ml BEDTools/2.31.1-GCC-13.3.0

# --- PATHS (Match your MACS2 output) ---
BASE_DIR="/scratch/njb42996"
PEAK_DIR="${BASE_DIR}/all_peak_calls"  # Where your .narrowPeak files are
TN5_DIR="${BASE_DIR}/processed_bams"   # Where your .clean.tn5.bed files are 1bp sliding
OUTPUT_DIR="${BASE_DIR}/refined_peaks"

# --- PARAMETERS ---
BIN=50
STEP=25
MAX_GAP=50
MIN_PEAK=150
# Use a common genome size for calculation (approx 2.1Gb for Maize/Teo)
GENOME_SIZE=

mkdir -p "$OUTPUT_DIR"

# Sample List (matches your MACS2 script)
SAMPLES=()

for SAMPLE in "${SAMPLES[@]}"; do
    echo "Processing refinement for: ${SAMPLE}"
    
    # Input files from your existing runs
    # start with high q value 
    PEAK_FILE="${PEAK_DIR}/q_0.1/${SAMPLE}.macs2_peaks.narrowPeak"
    TN5_BED="${TN5_DIR}/${SAMPLE}.clean.tn5.bed"
    
    if [ ! -f "$PEAK_FILE" ] || [ ! -f "$TN5_BED" ]; then
        echo "ERROR: Missing files for ${SAMPLE}. Skipping."
        continue
    fi

    NAME="${OUTPUT_DIR}/${SAMPLE}"

    # 1. Make windows across the MACS2 peak regions
    bedtools makewindows -b "$PEAK_FILE" -w $BIN -s $STEP | sort -k 1,1 -k2,2n > "${NAME}_windows.bed"

    # 2. Calculate coverage per window (tn5 hits / bin size)
    bedtools intersect -a "${NAME}_windows.bed" -b "$TN5_BED" -c | \
        awk -v b=$BIN '{print $1,$2,$3,$4,$4/b}' OFS="\t" > "${NAME}_windows.bg"

    # 3. Calculate Global Average Coverage
    total_reads=$(wc -l < "$TN5_BED")
    COV=$(bc <<< "scale=10; $total_reads / $GENOME_SIZE")
    echo "Global average coverage for ${SAMPLE}: $COV"

    # 4. Loop through Fold-Enrichment Cutoffs (2x to 10x)
    for CUTOFF in {2..10}; do
        MIN_COV=$(bc <<< "scale=10; $COV * $CUTOFF")
        
        # Filter, merge windows, and remove peaks shorter than 150bp
        cat "${NAME}_windows.bg" | \
            awk -v m="$MIN_COV" '$5 > m' | \
            bedtools merge -d $MAX_GAP -i - | \
            awk -v p=$MIN_PEAK '($3-$2) > p' > "${NAME}_${CUTOFF}xCov_refined_peak.bed"
    done

    # Clean up temp window files
    rm "${NAME}_windows.bed" "${NAME}_windows.bg"
    echo "Finished $SAMPLE"
done

