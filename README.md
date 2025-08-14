# EV Integration Analysis (ERP167546)

This repository contains alignment scripts, metadata, and soft-clip comparison tools associated with the ENA study accession **ERP167546**, focused on extracellular vesicle (EV) interactions and viral responses in BMDCs and HEK293T cells.

## 🔬 Experimental Overview

This dataset involves multiple experimental conditions across different cell types and treatment protocols. The overall ENA study accession is **ERP167546**.

### BMDCs Experiments [pod5]

| Treatment             | Submission Date | Run Accessions                          | Notes                             |
|----------------------|------------------|-----------------------------------------|-----------------------------------|
| ATEV (EV-treated)     | Jan 8th, 2025    | ERR14106287, ERR14106288                | Two technical replicate flowcells |
| PBS (control)         | Jan 24th, 2025   | ERR14208048, ERR14208049, ERR14208050   | Three technical replicate flowcells |
| Virus Ref 1           | Feb 16th, 2025   | ERR14376133, ERR14376134                | Two technical replicate flowcells |
| Virus Ref 2           | Jul 9, 2025   | ERR15277392                | One technical replicate flowcells |

### 293T Samples [pod5]

| Run Accession | Sample Description                |
|---------------|-----------------------------------|
| ERR15277390   | HEK293T treated with PBS          |
| ERR15277391   | HEK293T treated with virus_ref_3  |

### BMDCs and 293T Samples [fastq]

| Sample Description                  | Run Accession | File Name                                                     | Notes                             | Size (bytes)   |
|--------------------------------------|---------------|----------------------------------------------------------------|------------------------------------|----------------|
| HEK293T treated with virus_ref_3     | ERR15435818   | PAY43290_combined_Virus_293T.fastq.gz                          | Combined FASTQ                     | 100,889,391,034|
| HEK293T treated with PBS             | ERR15435817   | PAY39146_combined_PBS_293T.fastq.gz                            | Combined FASTQ                     | 72,064,431,107 |
| PBS-treated BMDM                     | ERR15435816   | combined_PBS_BMDM.fastq.gz                                     | Combined FASTQ                     | 144,627,113,608|
| EV-treated BMDM                      | ERR15435815   | combined_EV_BMDM.fastq.gz                                      | Combined FASTQ                     | 62,741,773,191 |
| Virus-treated BMDM (Virus Ref 1)     | ERR15435814   | combined_Virus_Treated_1_BMDM.fastq.gz                         | Combined FASTQ                     | 145,518,985,365|
| Virus-treated BMDM (Virus Ref 2)     | ERR15435813   | PAY42928_pass_combined_Virus_Treated_2_BMDM.fastq.gz           | Combined FASTQ                     | 114,042,846,728|

---

## 📁 Repository Structure

```bash
ev-integration/
├── FIGURE_S25B/                        # key scripts for figure generation
├── FIGURE_S25C/
├── LydenLab_alignment_scripts/        # SBATCH scripts for alignment to various references
├── LydenLab_pairwise_bam_comparisons/ # Scripts to compare soft-clipped reads across BAMs
├── LydenLab_subset_alignment_scripts/ # Gene Subset-specific alignment jobs
├── metadata/                          # Submission/sample metadata / spreadsheets for all samples
├── references/                        # Contains viral reference sequences (LydenLab_Virus_Ref 1,2,3)
```

### Methods & Versioning

DNA Libraries were prepared with the SQK-LSK114 gDNA Ligation Sequencing Kit and sequenced with FLO-PRO114M flow cells (Oxford Nanopore Technologies). Real-time basecalled reads were produced with MinKNOW Version 24.06.15 and aligned separately with minimap2 v2.28 to the UCSC hg38 reference genome (10.1101/gr.159624.113), UCSC mm10 reference genome and viral vector (LentiGuide-GFP.fa for BMDCs, Addgene# 200961 for the 293T cells). Selected gene coordinates were queried the UCSC genome browser (https://genome.ucsc.edu/cgi-bin/hgGateway). Reads associated with these genes were extracted with samtools v1.21. pysam v0.22.1 was used to extract left and right soft-clipped ends. Soft-clipped ends greater than or equal to 50 bp from either ATEVs or viral vector conditions were aligned to soft-clipped ends from the PBS condition with minimap2 v2.28. The ratio between the number of unaligned soft-clipped ends and total DNA count was then calculated to score gene integration.

### Key Script: `LydenLab_alignment_scripts/`

Includes pre-written `sbatch` scripts to align combined sample FASTQs against:
- **hg38**: Human genome (UCSC)
- **mm10**: Mouse genome (UCSC)
- **virus_ref_1`, `virus_ref_2`, `virus_ref_3**: Viral reference sequences

Each condition has multiple alignment targets:
```bash
align_combined_PBS_BMDM_hg38.sbatch
align_combined_PBS_BMDM_mm10.sbatch
align_combined_PBS_BMDM_virus_ref_1.sbatch
...
```

These use `minimap2` and `samtools` to produce sorted, indexed BAMs and alignment stats.

### Key Script: `LydenLab_pairwise_bam_comparisons/`

Scripts for pairwise BAM analysis focused on **soft-clipped read behavior**:
- `compare_softclips_bam_pair.py`: Compares soft-clip retention and re-alignment of virus-treated reads vs PBS.
- `summarize_softclip_unaligned_fraction.py`: Summarizes fraction of unaligned reads.
- `run_softclip_comparisons_sequential_V2.sh`: Sequential runner for comparisons.

---

## 🧬 References

The references used in alignment (hg38, mm10) were obtained from the **UCSC Genome Browser**. Viral references are located under:

```
references/LydenLab_Virus_Ref/
```

---

## 📎 Metadata Files

All ENA metadata (run accessions, dates, replicates) are found under `metadata/`, e.g.:

- `LydenLab_Run_Submission_BMDCs_EV_Treatment.txt`
- `LydenLab_Sample_Metadata_BMDCs_PBS_Treatment.tsv`
- etc.

---

## 📚 Citation

If you use this repository or data in your work, please cite the originating study linked to **ERP167546**.

---

For questions, contact **Theo Nelson** (thn4005@med.cornell.edu).
