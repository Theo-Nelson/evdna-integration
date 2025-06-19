#!/bin/bash

BASE="/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis"
ALIGN_DIR="$BASE/alignments_mm10_hg38_subset"
SCRIPT_DIR="$BASE/scripts"
ANALYSIS_DIR="$BASE/alignments_mm10_hg38_subset_comparisons"
PY_SCRIPT="$SCRIPT_DIR/compare_softclips_bam_pair.py"
THREADS=8

mkdir -p "$SCRIPT_DIR" "$ANALYSIS_DIR"

# Declare comparison groups
declare -A COMPARISONS=(
    ["combined_EV_BMDM"]="combined_PBS_BMDM"
    ["combined_Virus_Treated_1_BMDM"]="combined_PBS_BMDM"
    ["PAY42928_pass_combined_Virus_Treated_2_BMDM"]="combined_PBS_BMDM"
    ["PAY43290_combined_Virus_293T"]="PAY39146_combined_PBS_293T"
)

# Gene lists
HUMAN_GENES=("HLA-DMB" "HLA-DQB2" "HLA-DRA" "HLA-DRB1" "TAP1")
MOUSE_GENES=("H2-Aa" "H2-Ab1" "H2-DMb1" "H2-Eb2" "H2-K1" "Tap1")

# Activate environment

# Loop over comparison pairs
for VIRUS in "${!COMPARISONS[@]}"; do
    PBS="${COMPARISONS[$VIRUS]}"

    if [[ "$VIRUS" == "PAY43290_combined_Virus_293T" ]]; then
        GENES=("${HUMAN_GENES[@]}")
        LABEL="human"
    else
        GENES=("${MOUSE_GENES[@]}")
        LABEL="mouse"
    fi

    for GENE in "${GENES[@]}"; do
        VIRUS_BAM="$ALIGN_DIR/${VIRUS}.all.sorted_${LABEL}_${GENE}.bam"
        PBS_BAM="$ALIGN_DIR/${PBS}.all.sorted_${LABEL}_${GENE}.bam"
        OUTDIR="$ANALYSIS_DIR/${VIRUS}_vs_${PBS}/${GENE}"
        mkdir -p "$OUTDIR"

        echo "[*] Running comparison: ${VIRUS} vs ${PBS} for ${GENE}"

        # Check BAMs exist
        if [[ ! -f "$VIRUS_BAM" || ! -f "$PBS_BAM" ]]; then
            echo "[!] Skipping $GENE: Missing BAM(s)"
            continue
        fi

        # Count reads
        V_COUNT=$(samtools view -c "$VIRUS_BAM")
        P_COUNT=$(samtools view -c "$PBS_BAM")

        if [[ $V_COUNT -eq 0 || $P_COUNT -eq 0 ]]; then
            echo "[!] Skipping $GENE: One or both BAMs empty"
            continue
        fi

        # Subsample if needed
        if [[ $V_COUNT -gt 25000 ]]; then
            samtools view -s 0.42 -b "$VIRUS_BAM" > "$OUTDIR/virus.subsampled.bam"
        else
            cp "$VIRUS_BAM" "$OUTDIR/virus.subsampled.bam"
        fi

        if [[ $P_COUNT -gt 25000 ]]; then
            samtools view -s 0.24 -b "$PBS_BAM" > "$OUTDIR/pbs.subsampled.bam"
        else
            cp "$PBS_BAM" "$OUTDIR/pbs.subsampled.bam"
        fi

        # Index
        samtools index "$OUTDIR/virus.subsampled.bam"
        samtools index "$OUTDIR/pbs.subsampled.bam"

        # Run the Python comparison
        python "$PY_SCRIPT" \
            --virus_bam "$OUTDIR/virus.subsampled.bam" \
            --pbs_bam "$OUTDIR/pbs.subsampled.bam" \
            --output_dir "$OUTDIR" \
            --min_clip 50 \
            --threads $THREADS

        echo "[✓] Finished $GENE\n"
    done
done

echo "[✓] All softclip comparisons complete."

