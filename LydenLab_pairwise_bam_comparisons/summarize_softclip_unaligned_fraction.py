import os
import csv

base_dir = "/athena/masonlab/scratch/users/thn4005/scripts/projects_v2/Di-Ao/brand_new_analysis/alignments_mm10_hg38_subset_comparisons"
output_csv = os.path.join(base_dir, "comparison_summary_softclip_unaligned_fraction.csv")

summary_rows = []
header = ["Comparison", "Gene", "Virus_total_unaligned_to_PBS", "Virus_total_pre_filter", "Fraction_Unaligned"]

for comparison in sorted(os.listdir(base_dir)):
    comp_path = os.path.join(base_dir, comparison)
    if not os.path.isdir(comp_path):
        continue

    for gene in sorted(os.listdir(comp_path)):
        gene_path = os.path.join(comp_path, gene)
        summary_file = os.path.join(gene_path, "softclip_summary.csv")
        if not os.path.isfile(summary_file):
            continue

        virus_total_pre = None
        virus_unaligned = None

        with open(summary_file) as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) != 2 or row[0] == "Metric":
                    continue
                key, val = row
                if key == "Virus_total_pre_filter":
                    virus_total_pre = int(val)
                elif key == "Virus_total_unaligned_to_PBS":
                    virus_unaligned = int(val)

        if virus_total_pre is not None and virus_unaligned is not None:
            fraction = virus_unaligned / virus_total_pre if virus_total_pre > 0 else 0.0
            summary_rows.append([comparison, gene, virus_unaligned, virus_total_pre, round(fraction, 4)])

# Write combined summary
with open(output_csv, "w", newline="") as out:
    writer = csv.writer(out)
    writer.writerow(header)
    writer.writerows(summary_rows)

print(f"[✓] Summary written to: {output_csv}")

