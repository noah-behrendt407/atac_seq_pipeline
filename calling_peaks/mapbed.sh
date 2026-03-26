#!/bin/bash
#SBATCH -J kmerizing_ref-1bp_step-150bp_win
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH -e %x-%J.err
#SBATCH -o %x-%J.out
#SBATCH -t 48:00:00
#SBATCH --mem=100GB
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch

# Load Module
ml BEDTools/2.31.1-GCC-13.3.0
ml SAMtools/1.18-GCC-12.3.0
ml BWA/0.7.18-GCCcore-13.3.0

workDir=""
chromFile="${workDir}/    ChromonlySizes.txt"
winSize=150
stepSize=1
genomeFasta="${workDir}/ .fa"
genomePrefix="${workDir}/ "
kmerFasta="${workDir}/   1bp_step-150bp_kmers.fa"

bedtools makewindows -g ${chromFile} -w ${winSize} -s ${stepSize} | bedtools getfasta -fi ${genomeFasta} -bed stdin -fo ${kmerFasta}
echo "genome has been kmerized proceed to alligining"
bwa mem -t 8 ${genomePrefix} ${kmerFasta} | samtools view -@ 8 -h -b -q 10 -o ${workDir}/mappable_kmers.bam -
echo "allignment is done proceed to sorting and merging"
samtools sort -@ 8 -m 10G ${workDir}/mappable_kmers.bam -o ${workDir}/mappable_kmers_sorted.bam 
echo "sorting is done proceed to merging"
bedtools bamtobed -i ${workDir}/mappable_kmers_sorted.bam | bedtools merge -i stdin > ${workDir}/mappable_BED.bed