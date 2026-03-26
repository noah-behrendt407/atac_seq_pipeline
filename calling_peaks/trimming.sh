#!/bin/bash								
#SBATCH -e trimming-%J.err     #sets the file for error messages, %J is is the jobs ID number
#SBATCH -o trimming-%J.out     #sets the file for the results
#SBATCH -J trimming_all_samples       #sets the name of my job to be trim_all_samples
#SBATCH -t 48:00:00  					#sets the maximum time limit in hours of the job
#SBATCH --mem=8GB 						#sets the maximum memory to be used by the job 	
#SBATCH -n 1							#you want 1 task
#SBATCH -c 16							#requests four CPUs
#SBATCH -p batch 						#specifies the partition to submit to sbatch

# =============================================================================
# ATAC-seq Trimming Pipeline - Configuration Section
# =============================================================================
# Edit the variables below for your specific project

# Base configuration
BASE_DIR="/scratch/njb42996"
WORKING_DIR="${BASE_DIR}/your_working_directory_name"

#creates variables and gives the direct path of where they are, how will it find the fastq and adapter files and where will it store trimmed reads
INPUT_DIR="${WORKING_DIR}/raw_data"
OUTPUT_DIR="${WORKING_DIR}/trimmed_reads"
ADAPTER_DIR="${WORKING_DIR}/adapters"

# Sample Names (edit this list for your samples)
#each sample has R1 and R2 (f and reverse reads)
#just provide the base name for the R1 and R1
#SAMPLE tells the computer to use these titles as common identifiers between pairs
SAMPLES=(
   
)

# File naming pattern (adjust if your files have different naming)
FILE_SUFFIX=".fastq.gz"  # Updated to remove _001
R1_PATTERN="_R1"
R2_PATTERN="_R2"

# Trimmomatic Parameters (adjust as needed)
THREADS=8
ADAPTER_FILE="${ADAPTER_DIR}/TruSeq3-PE.fa"
ILLUMINACLIP_PARAMS="2:30:10"  #Controls how strict adapter removal is (2 mismatches allowed, palindrome threshold 30, simple threshold 10)
SLIDINGWINDOW_PARAMS="4:15" # Quality filtering in 4-base windows, drops if average quality drops below 15
LEADING=3 #Removes poor quality bases (< 3) from read ends
TRAILING=3
MINLEN=30 #Discards reads shorter than 30 bases after all trimming

# =============================================================================
# Pipeline Execution - No need to edit below this line
# =============================================================================

echo "Starting ATAC-seq trimming pipeline for project: ${PROJECT_NAME}"
echo "Working directory: ${WORKING_DIR}"
echo "Processing ${#SAMPLES[@]} samples"
echo "========================================================================"

# Load the module  #downloads the trimmomatic software to be used
ml Trimmomatic/0.39-Java-11         

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

#Need to download adapters in order to process atac data
# Download adapters if they don't exist
if [ ! -f "${ADAPTER_FILE}" ]; then
    echo "Downloading TruSeq3-PE adapters..."
    mkdir -p "${ADAPTER_DIR}"
    wget -O "${ADAPTER_FILE}" https://raw.githubusercontent.com/timflutre/trimmomatic/master/adapters/TruSeq3-PE.fa
    echo "Adapters downloaded successfully"
fi

# Process each sample
for SAMPLE in "${SAMPLES[@]}"; do
    #pritns processing sample: $SAMPLE to see the porgress in the output file 
    echo "Processing sample: ${SAMPLE}"
    
    #Defines the INPUT_R1 and INPUT_R2, and it uses the INPUT_DIR variables we created earlier 
    INPUT_R1="${INPUT_DIR}/${SAMPLE}${R1_PATTERN}${FILE_SUFFIX}"
    INPUT_R2="${INPUT_DIR}/${SAMPLE}${R2_PATTERN}${FILE_SUFFIX}"
    
    # Check if input files exist
    if [ ! -f "${INPUT_R1}" ] || [ ! -f "${INPUT_R2}" ]; then
        echo "ERROR: Input files not found for sample ${SAMPLE}"
        echo "  Expected: ${INPUT_R1}"
        echo "  Expected: ${INPUT_R2}"
        continue
    fi
    
    #creates four sets of output data, good quality forward reads, unpaired forward reads, good quality reverse reads, unpaired reverse reads 
    OUTPUT_R1_PAIRED="${OUTPUT_DIR}/${SAMPLE}_R1_paired.fastq.gz"
    OUTPUT_R1_UNPAIRED="${OUTPUT_DIR}/${SAMPLE}_R1_unpaired.fastq.gz"
    OUTPUT_R2_PAIRED="${OUTPUT_DIR}/${SAMPLE}_R2_paired.fastq.gz"
    OUTPUT_R2_UNPAIRED="${OUTPUT_DIR}/${SAMPLE}_R2_unpaired.fastq.gz"
    
    #trimmomatic doing its thing 
    trimmomatic PE -threads ${THREADS} \
        "${INPUT_R1}" \
        "${INPUT_R2}" \
        "${OUTPUT_R1_PAIRED}" \
        "${OUTPUT_R1_UNPAIRED}" \
        "${OUTPUT_R2_PAIRED}" \
        "${OUTPUT_R2_UNPAIRED}" \
        ILLUMINACLIP:${ADAPTER_FILE}:${ILLUMINACLIP_PARAMS} \
        SLIDINGWINDOW:${SLIDINGWINDOW_PARAMS} \
        LEADING:${LEADING} \
        TRAILING:${TRAILING} \
        MINLEN:${MINLEN}
    
    if [ $? -eq 0 ]; then
        echo "Finished processing: ${SAMPLE}"
    else
        echo "  ✗ Error processing: ${SAMPLE}"
    fi
    echo "----------------------------------------"
done

echo "All samples processed!"
echo "Results saved in: ${OUTPUT_DIR}"
