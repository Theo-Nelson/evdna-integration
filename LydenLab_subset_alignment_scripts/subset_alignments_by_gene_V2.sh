#!/bin/bash
set -euo pipefail

# Define paths
ROOT_DIR="/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis"
ALIGN_DIR="${ROOT_DIR}/alignments_mm10_hg38"
SUBSET_DIR="${ROOT_DIR}/alignments_mm10_hg38_subset"
mkdir -p "${SUBSET_DIR}"

# BED files with user-provided coordinates
HUMAN_BED="${SUBSET_DIR}/human_genes.bed"
MOUSE_BED="${SUBSET_DIR}/mouse_genes.bed"

# Create human BED
cat <<EOF > "$HUMAN_BED"
chr6	32934635	32941028	HLA-DMB
chr6	32756097	32763532	HLA-DQB2
chr6	32439886	32445046	HLA-DRA
chr6	32578774	32589848	HLA-DRB1
chr6	32845208	32853704	TAP1
chr6	32741391	32747198	HLA-DQA2
chr6	32659467	32666657	HLA-DQB1
chr6	31353875	31357179	HLA-B
chr6	31268749	31272092	HLA-C
chr6	29723434	29727296	HLA-F
EOF

# Create mouse BED
cat <<EOF > "$MOUSE_BED"
chr17	34282743	34287823	H2-Aa
chr17	34263208	34269419	H2-Ab1
chr17	34153071	34160230	H2-DMb1
chr17	34325664	34341412	H2-Eb2
chr17	33996052	34000347	H2-K1
chr17	34187552	34197225	Tap1
EOF

# Subset BAMs and count reads
subset_and_count() {
    local bam_file="$1"
    local bed_file="$2"
    local label="$3"
    local count_file="${SUBSET_DIR}/${label}_alignment_counts.tsv"
    local base=$(basename "$bam_file" .bam)

    echo -e "Sample\tGene\tReadCount" >> "$count_file"

    while read -r chr start end gene; do
        region="${chr}:${start}-${end}"
        out_bam="${SUBSET_DIR}/${base}_${label}_${gene}.bam"
        samtools view -b "$bam_file" "$region" > "$out_bam"
        samtools index "$out_bam"
        nreads=$(samtools view "$out_bam" | wc -l)
        echo -e "$base\t$gene\t$nreads" >> "$count_file"
    done < "$bed_file"
}

# Process human-aligned BAMs
echo "[INFO] Subsetting human-aligned BAMs..."
for bam in "$ALIGN_DIR"/*__hg38/*.all.sorted.bam; do
    [ -f "$bam" ] && subset_and_count "$bam" "$HUMAN_BED" "human"
done

# Process mouse-aligned BAMs
echo "[INFO] Subsetting mouse-aligned BAMs..."
for bam in "$ALIGN_DIR"/*__mm10/*.all.sorted.bam; do
    [ -f "$bam" ] && subset_and_count "$bam" "$MOUSE_BED" "mouse"
done

echo "[DONE] All BAMs processed and subsetted successfully."

