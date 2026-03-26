#!/bin/bash
#SBATCH -e ref_setup-%J.err
#SBATCH -o ref_setup-%J.out
#SBATCH -J ref_setup
#SBATCH -t 48:00:00
#SBATCH --mem=100GB
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch

# =============================================================================
# Download ref (.fa.gz) → gunzip → bwa index → samtools faidx → chrom sizes
# =============================================================================

ml BWA/0.7.18-GCCcore-13.3.0
ml SAMtools/1.18-GCC-12.3.0

# -------------------- Paths / names (you fill in) --------------------
BASE_DIR="/scratch/njb42996/atac"
WORKING_DIR="${BASE_DIR}/maize"

REF_GENOME_DIR="${WORKING_DIR}/maize_ref_genome"
REF_URL="https://download.maizegdb.org/Zm-B104-REFERENCE-CORTEVA-1.0/Zm-B104-REFERENCE-CORTEVA-1.0.fa.gz"

REF_FA_GZ="${REF_GENOME_DIR}/Zm-B104-REFERENCE-CORTEVA-1.0.fa.gz"
REF_FA="${REF_GENOME_DIR}/Zm-B104-REFERENCE-CORTEVA-1.0.fa"

# BWA index prefix name (this is what your alignments will point to with bwa mem)
BWA_PREFIX="${REF_GENOME_DIR}/Zm-B104-REFERENCE-CORTEVA-1.0"

# Chrom sizes output
CHROMSIZES_DIR="${REF_GENOME_DIR}"
CHROMSIZES_FILE="${CHROMSIZES_DIR}/your_genome_name-chromSizes.txt"
# --------------------------------------------------------------------

mkdir -p "${REF_GENOME_DIR}"

echo "Reference setup starting"
echo "REF_GENOME_DIR:   ${REF_GENOME_DIR}"
echo "REF_URL:          ${REF_URL}"
echo "BWA_PREFIX:       ${BWA_PREFIX}"
echo "CHROMSIZES_FILE:  ${CHROMSIZES_FILE}"
echo "========================================================================"

echo "1 Downloading reference (.fa.gz) with wget"
wget -P "${REF_GENOME_DIR}" "${REF_URL}"
echo "✓ Download complete"

echo "2 Decompressing reference (.fa.gz → .fa)"
gunzip "${REF_FA_GZ}"
echo "✓ Decompression complete"

echo "3 Building BWA index"
bwa index -p "${BWA_PREFIX}" "${REF_FA}"
echo "✓ BWA index complete"

echo "4 Building samtools FASTA index (.fai)"
samtools faidx "${REF_FA}"
echo "✓ samtools faidx complete"

echo "5 Writing chromosome sizes file (cut -f1,2 from .fai)"
cut -f1,2 "${REF_FA}.fai" > "${CHROMSIZES_FILE}"
echo "✓ Chromosome sizes written"

echo ""
echo "First 10 chromosomes/contigs:"
head -10 "${CHROMSIZES_FILE}"

echo ""
TOTAL_CHROMS=$(wc -l < "${CHROMSIZES_FILE}")
echo "Total chromosomes/contigs: ${TOTAL_CHROMS}"

echo "Reference setup complete!"


####Extra Step to generate chr size file adjust for your genome ####
grep -E '^chr([1-9]|10)[[:space:]]' ..._Sizes.txt > ..ChromonlySizes.txt
#clean the chromosome text file to get rid of extra contigs that are not main chromosomes 
