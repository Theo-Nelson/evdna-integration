# EV Integration Analysis (ERP167546)

This repository contains alignment scripts, metadata, and soft-clip comparison tools associated with the ENA study accession **ERP167546**, focused on extracellular vesicle (EV) interactions and viral responses in BMDCs and HEK293T cells.

## 🔬 Experimental Overview

This dataset involves multiple experimental conditions across different cell types and treatment protocols. The overall ENA study accession is **ERP167546**.

### BMDCs Experiments

| Treatment             | Submission Date | Run Accessions                          | Notes                             |
|----------------------|------------------|-----------------------------------------|-----------------------------------|
| ATEV (EV-treated)     | Jan 8th, 2025    | ERR14106287, ERR14106288                | Two technical replicate flowcells |
| PBS (control)         | Jan 24th, 2025   | ERR14208048, ERR14208049, ERR14208050   | Three technical replicate flowcells |
| Virus Ref 1           | Feb 16th, 2025   | ERR14376133, ERR14376134                | Two technical replicate flowcells |

### 9th July 2025 Samples

| Run Accession | Sample Description                |
|---------------|-----------------------------------|
| ERR15277390   | HEK293T treated with PBS          |
| ERR15277391   | HEK293T treated with virus_ref_3  |
| ERR15277392   | BMDCs treated with virus_ref_2    |

---

## 📁 Repository Structure

```bash
ev-integration/
├── FIGURE_S25B/                        # Placeholder or figure outputs
├── FIGURE_S25C/
├── LydenLab_alignment_scripts/        # SBATCH scripts for alignment to various references
├── LydenLab_pairwise_bam_comparisons/ # Scripts to compare soft-clipped reads across BAMs
├── LydenLab_subset_alignment_scripts/ # Subset-specific alignment jobs
├── metadata/                          # Submission/sample metadata for all BMDC conditions
├── references/                        # Contains viral reference sequences (LydenLab_Virus_Ref)
```

### 🔧 `LydenLab_alignment_scripts/`

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

### 🧪 `LydenLab_pairwise_bam_comparisons/`

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

For questions or collaboration, contact **Theo Nelson**.
