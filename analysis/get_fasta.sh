#!/bin/bash
#SBATCH -e get_fasta-%J.err
#SBATCH -o get_fasta-%J.out
#SBATCH -J get_fasta
#SBATCH -t 48:00:00
#SBATCH --mem=50GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=njb42996@uga.edu
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p batch

ml BEDTools/2.31.1-GCC-13.3.0

ref=""
peaks_dir=""
fa_dir=""

mkdir -p ${fa_dir}

for file in "${peaks_dir}"/Consensus_*.bed; do
    # Strip the path and extension to get a clean name
    base=$(basename "$file" .bed)
    
    echo "Getting fasta for: $base"
    
   
    bedtools getfasta -fi "${ref}" -bed "$file" -fo "${fa_dir}/sequences_${base}.fa"
done


#extract just genes of interest
#grep -Fwf "/path/to/genes_of_interest.txt" "path/to/fasta" > "/pathto/new/fasta/subfile"