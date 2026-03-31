# atac_seq_pipeline
- scripts for processing bulk atac_seq data 


1. Adapter Download 
mkdir -p /scratch/njb42996/{WORKING_DIR}/adapters
wget -O /scratch/njb42996/{WORKING_DIR}/adapters/TruSeq3-PE.fa https://raw.githubusercontent.com/timflutre/trimmomatic/master/adapters/TruSeq3-PE.fa

2. Trimming adapdters and low quality base calls 
- use trimming.sh

3. Set up the reference genome 
- use ref_genome_setup.sh
- generate a file with the sizes of the main chromosomes 

4. Generate a bed file with that contain only the regions of the genome which are mappable 
- use mapbed.sh

5. Alignment 
- use alignment.sh
- generates alignment statistics that are important downstream

6. Clean Alignments 
- use clean_alignments.sh

7. Call Peaks
- use peak_call.sh
- calls peaks at multiple q values and generates frip statisitcs for each q value 

8. Refine Peaks
- use refine_peaks.sh
- removes peaks which are too small, not enriched beyond background, trims peaks

9. BedGraph to BigWig
- use bed2big
- note the array
- generate bigwig files to view Tn5 integration 
- takes 1bp clean tn5 and makes it 50bp window 

10. Refined Frip
- generate frips for all the different stringencies 
- best for bulk and seeing which stringency is best along with visualization
