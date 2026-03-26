#!/bin/bash
#SBATCH -e macs2-%J.err
#SBATCH -o macs2-%J.out
#SBATCH -J macs2_multi_q
#SBATCH -t 48:00:00
#SBATCH --mem=150GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch

# =============================================================================
# ATAC-seq Peak Calling Pipeline - Configuration Section
# =============================================================================
BASE_DIR="/scratch/njb42996/"
WORKING_DIR="${BASE_DIR}/"

PROCESSED_DIR="${WORKING_DIR}/processed_bams"

# NEW: Master directory and FRiP directory
MASTER_PEAKS_DIR="${WORKING_DIR}/all_peak_calls"
FRIP_REPORT_DIR="${WORKING_DIR}/frip_reports"

# NEW: Range of Q-values to test
Q_VALUES=(0.1 0.05 0.01 0.001)

SAMPLES=(

)

#use genome size of mappable regions ie. mappable.bed
GENOME_SIZE=""
GENERATE_BEDGRAPH=true
CUTOFF_ANALYSIS=true
BED_SUFFIX=".clean.tn5.bed"

# =============================================================================
# Pipeline Execution
# =============================================================================
ml MACS2/2.2.9.1-foss-2023a
ml SAMtools/1.18-GCC-12.3.0
ml BEDTools/2.31.1-GCC-13.3.0

mkdir -p "${MASTER_PEAKS_DIR}"
mkdir -p "${FRIP_REPORT_DIR}"

# --- OUTER LOOP: Iterate through each Q-value ---
for Q_VAL in "${Q_VALUES[@]}"; do
    
    # Create a sub-directory for this specific q-value
    CURRENT_Q_DIR="${MASTER_PEAKS_DIR}/q_${Q_VAL}"
    mkdir -p "${CURRENT_Q_DIR}"
    
    # Create a FRiP report file for this q-value
    REPORT_FILE="${FRIP_REPORT_DIR}/FRiP_report_q${Q_VAL}.txt"
    echo -e "Sample\tTotal_Reads\tReads_In_Peaks\tFRiP" > "${REPORT_FILE}"

    echo "Running Peak Calling for Q-Value: ${Q_VAL}"
  
    # Iterate through each Sample 
    for SAMPLE in "${SAMPLES[@]}"; do
        INPUT_BED="${PROCESSED_DIR}/${SAMPLE}${BED_SUFFIX}"
        
        if [ ! -f "${INPUT_BED}" ]; then
            echo "ERROR: Input BED file not found for sample ${SAMPLE}"
            continue
        fi
		# no chip model, keep dups because we already removed them
		#take the single basepair cut site, subtract 75 and add 150 creating a 150bp window of accessibility at the cut site 
        MACS_FLAGS="--nomodel --keep-dup all --extsize 150 --shift -75"

        # Run MACS2 
        macs2 callpeak -t "${INPUT_BED}" -f BED -g "${GENOME_SIZE}" -q "${Q_VAL}" --outdir "${CURRENT_Q_DIR}" \
            -n "${SAMPLE}.macs2" ${MACS_FLAGS} --bdg --cutoff-analysis
        
        if [ $? -eq 0 ]; then
            NARROWPEAK="${CURRENT_Q_DIR}/${SAMPLE}.macs2_peaks.narrowPeak"
            MERGED_PEAK="${CURRENT_Q_DIR}/${SAMPLE}.macs2_merged_peak.bed"
            
            sort -T "${WORKING_DIR}" -k1,1 -k2,2n "${NARROWPEAK}" | bedtools merge -d 150 -i stdin | awk '($3-$2) >= 50' > "${MERGED_PEAK}"
            
            # FRiP Calculation logic (identical to yours)
            total_num=$(wc -l < "${INPUT_BED}")
            RiP=$(bedtools intersect -a "${INPUT_BED}" -b "${MERGED_PEAK}" -u | wc -l)
            frip=$(bc <<< "scale=4; ${RiP}/${total_num}")
            
            # NEW: Append results to the Master FRiP Report instead of just echo
            echo -e "${SAMPLE}\t${total_num}\t${RiP}\t${frip}" >> "${REPORT_FILE}"
            
            echo "  ✓ Finished ${SAMPLE} at q=${Q_VAL}. FRiP: ${frip}"
        fi
    done
done

echo "All Q-values and samples processed!"

# =============================================================================
# Summary of Outputs
# =============================================================================
# This script has organized results into: ${MASTER_PEAKS_DIR}/q_{value}/
# 
# Per Sample/Q-value Outputs:
# 1. {sample}.macs2_peaks.narrowPeak    - Raw peak coordinates (MACS2 standard)
# 2. {sample}.macs2_merged_peak.bed     - Final cleaned peaks (Sorted, Merged >150bp, Filtered >50bp)
# 3. {sample}.macs2_summits.bed         - Exact point of highest signal within peaks
# 4. {sample}.macs2_peaks.xls           - Metadata and fold-enrichment stats
# 5. {sample}.macs2_treat_pileup.bdg    - Browser track (Pileup of centered 150bp windows)
# 
# Master Reports:
# - ${FRIP_REPORT_DIR}/FRiP_report_q{value}.txt - Tab-separated FRiP scores for all samples
# =============================================================================
