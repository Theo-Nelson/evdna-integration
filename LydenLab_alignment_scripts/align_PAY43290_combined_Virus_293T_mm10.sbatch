#!/bin/bash
#SBATCH --partition=scu-cpu
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --job-name=align_PAY43290_combined_Virus_293T_mm10
#SBATCH --output=/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis/alignments_mm10_hg38/PAY43290_combined_Virus_293T__mm10/%x.out

# Tools
MINIMAP2="/athena/masonlab/scratch/users/thn4005/programs/minimap2-2.28_x64-linux/minimap2"
SAMTOOLS="/athena/masonlab/scratch/users/thn4005/programs/samtools-1.21/samtools"

# Inputs
FASTQ="/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis/fastq/PAY43290_combined_Virus_293T.fastq.gz"
REFERENCE="/athena/masonlab/scratch/users/thn4005/scripts/references_v2/references/murine/mm10/mm10.fa"
WORKDIR="/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis/alignments_mm10_hg38/PAY43290_combined_Virus_293T__mm10"
THREADS=32

# Outputs
SAM="$WORKDIR/PAY43290_combined_Virus_293T.sam"
ALL_BAM="$WORKDIR/PAY43290_combined_Virus_293T.all.bam"
SORTED_ALL_BAM="$WORKDIR/PAY43290_combined_Virus_293T.all.sorted.bam"
ALIGNED_BAM="$WORKDIR/PAY43290_combined_Virus_293T.aligned.sorted.bam"
UNALIGNED_BAM="$WORKDIR/PAY43290_combined_Virus_293T.unaligned.bam"
STATS_ALL="$WORKDIR/PAY43290_combined_Virus_293T.all.stats.txt"
STATS_ALIGNED="$WORKDIR/PAY43290_combined_Virus_293T.aligned.stats.txt"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[$(date)] Starting minimap2 alignment..." | tee -a run.log
"$MINIMAP2" -ax map-ont -t "$THREADS" --secondary=no "$REFERENCE" "$FASTQ" > "$SAM"

echo "[$(date)] Converting SAM to BAM..." | tee -a run.log
"$SAMTOOLS" view -@ "$THREADS" -bS "$SAM" > "$ALL_BAM"

echo "[$(date)] Sorting BAM..." | tee -a run.log
"$SAMTOOLS" sort -@ "$THREADS" -o "$SORTED_ALL_BAM" "$ALL_BAM"
"$SAMTOOLS" index "$SORTED_ALL_BAM"

echo "[$(date)] Extracting aligned reads..." | tee -a run.log
"$SAMTOOLS" view -@ "$THREADS" -b -F 4 "$SORTED_ALL_BAM" > "$ALIGNED_BAM"
"$SAMTOOLS" index "$ALIGNED_BAM"

echo "[$(date)] Extracting unaligned reads..." | tee -a run.log
"$SAMTOOLS" view -@ "$THREADS" -b -f 4 "$SORTED_ALL_BAM" > "$UNALIGNED_BAM"

echo "[$(date)] Computing stats..." | tee -a run.log
"$SAMTOOLS" stats "$SORTED_ALL_BAM" > "$STATS_ALL"
"$SAMTOOLS" stats "$ALIGNED_BAM" > "$STATS_ALIGNED"

rm -f "$SAM" "$ALL_BAM"

echo "[$(date)] Alignment complete for $FASTQ vs $REFERENCE" | tee -a run.log
