#!/bin/bash
#SBATCH -e alignments-%J.err     #sets the file for error messages, %J is the job ID number
#SBATCH -o alignments-%J.out     #sets the file for the results
#SBATCH -J alignments            #sets the name of the job
#SBATCH -t 48:00:00              #sets the maximum time limit in hours of the job
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH --mem=16GB               #sets the maximum memory to be used by the job
#SBATCH -n 1                     #you want 1 task
#SBATCH -c 16                    #requests CPUs (should match THREADS variable below)
#SBATCH -p batch                 #specifies the partition to submit to sbatch

# =============================================================================
# ATAC-seq Alignment Pipeline - Configuration Section
# =============================================================================
# Edit the variables below for your specific project

# Base Configuration
BASE_DIR="/scratch/njb42996"
WORKING_DIR="${BASE_DIR}/your_working_directory_name"

# Directory paths
TRIMMED_DIR="${WORKING_DIR}/trimmed_reads"
ALIGNMENTS_DIR="${WORKING_DIR}/alignments"
REF_GENOME_DIR="${WORKING_DIR}/ref_genome_dir"

# Reference genome configuration, just put the indexed name with no extensions
INDEXED_GENOME="${REF_GENOME_DIR}/your_indexed_genome_name"

# Sample Names (edit this list for your samples)
# Add your sample base names here (without _R1/_R2 suffixes)
SAMPLES=(
    "sample1_name"
    "sample2_name"
    "sample3_name"
)

# BWA Parameters
THREADS=15                       # Number of CPU cores to use (MUST match SBATCH -c parameter above)
BWA_OPTIONS="-M"                 # -M: mark shorter split hits as secondary for Picard compatibility

# NOTE: If you change THREADS, also update the SBATCH -c parameter at the top of this file

# =============================================================================
# Pipeline Execution - No need to edit below this line
# =============================================================================

echo "Starting ATAC-seq alignment pipeline"
echo "Working directory: ${WORKING_DIR}"
echo "Reference genome: ${INDEXED_GENOME}"
echo "Processing ${#SAMPLES[@]} samples"
echo "========================================================================"

# Load the BWA module
ml BWA/0.7.18-GCCcore-13.3.0

# Create alignments directory if it doesn't exist
mkdir -p "${ALIGNMENTS_DIR}"

# Check if reference genome exists
if [ ! -f "${INDEXED_GENOME}.bwt" ]; then
    echo "ERROR: Indexed reference genome not found at ${INDEXED_GENOME}"
    echo "Please ensure the genome has been indexed with 'bwa index'"
    exit 1
fi

# Process each sample
for SAMPLE in "${SAMPLES[@]}"; do
    echo "Processing sample: ${SAMPLE}"
    
    # Define input files (paired trimmed reads)
    INPUT_R1="${TRIMMED_DIR}/${SAMPLE}_R1_paired.fastq.gz"
    INPUT_R2="${TRIMMED_DIR}/${SAMPLE}_R2_paired.fastq.gz"
    
    # Check if input files exist
    if [ ! -f "${INPUT_R1}" ] || [ ! -f "${INPUT_R2}" ]; then
        echo "ERROR: Trimmed input files not found for sample ${SAMPLE}"
        echo "  Expected: ${INPUT_R1}"
        echo "  Expected: ${INPUT_R2}"
        continue
    fi
    
    # Define output file
    OUTPUT_SAM="${ALIGNMENTS_DIR}/${SAMPLE}.sam"
    
    echo "  Aligning ${SAMPLE} to reference genome..."
    echo "  Input R1: ${INPUT_R1}"
    echo "  Input R2: ${INPUT_R2}"
    echo "  Output: ${OUTPUT_SAM}"
    
    # Run BWA mem alignment
    bwa mem ${BWA_OPTIONS} -t ${THREADS} \
        "${INDEXED_GENOME}" \
        "${INPUT_R1}" \
        "${INPUT_R2}" \
        > "${OUTPUT_SAM}"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Finished aligning: ${SAMPLE}"
        
        # Check output file size
        SAM_SIZE=$(stat -f%z "${OUTPUT_SAM}" 2>/dev/null || stat -c%s "${OUTPUT_SAM}" 2>/dev/null)
        echo "  Output file size: $(( SAM_SIZE / 1024 / 1024 )) MB"
    else
        echo "  ✗ Error aligning: ${SAMPLE}"
    fi
    echo "----------------------------------------"
done

echo "All samples processed!"
echo "Results saved in: ${ALIGNMENTS_DIR}"