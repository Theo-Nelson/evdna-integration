import os
import argparse
import pysam
import subprocess
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio import SeqIO
from collections import defaultdict
import csv

# ------------------ CLI ------------------

parser = argparse.ArgumentParser(description="Compare soft-clipped reads from BAMs")
parser.add_argument("--virus_bam", required=True, help="Path to virus BAM (subsampled)")
parser.add_argument("--pbs_bam", required=True, help="Path to PBS BAM (subsampled)")
parser.add_argument("--output_dir", required=True, help="Output directory")
parser.add_argument("--min_clip", type=int, default=50, help="Minimum soft-clip length")
parser.add_argument("--threads", type=int, default=4, help="Threads for minimap2")
args = parser.parse_args()

virus_bam = args.virus_bam
pbs_bam = args.pbs_bam
output_dir = args.output_dir
min_clip = args.min_clip
threads = args.threads

os.makedirs(output_dir, exist_ok=True)

minimap2_path = "/athena/masonlab/scratch/users/thn4005/programs/minimap2-2.28_x64-linux/minimap2"
summary_metrics = {}

# ------------------ Soft-clip Extraction ------------------

def extract_softclips(bam_path, fasta_out, min_clip=50):
    bam = pysam.AlignmentFile(bam_path, "rb")
    softclip_seqs = []
    kept = 0
    filtered = 0

    for read in bam.fetch():
        if read.is_unmapped or read.cigartuples is None:
            continue
        seq = read.query_sequence
        cigar = read.cigartuples

        if cigar[0][0] == 4:
            clip_len = cigar[0][1]
            if clip_len >= min_clip:
                softclip_seqs.append((read.query_name + "_left", seq[:clip_len]))
                kept += 1
            else:
                filtered += 1

        if cigar[-1][0] == 4:
            clip_len = cigar[-1][1]
            if clip_len >= min_clip:
                softclip_seqs.append((read.query_name + "_right", seq[-clip_len:]))
                kept += 1
            else:
                filtered += 1

    bam.close()

    records = [SeqRecord(Seq(s), id=name, description="") for name, s in softclip_seqs]
    SeqIO.write(records, fasta_out, "fasta")
    print(f"[✓] Wrote {len(records)} sequences to {fasta_out}")
    print(f"[QC] {kept} kept, {filtered} filtered (<{min_clip} bp)\n")

    return {
        "read_names": [name for name, _ in softclip_seqs],
        "kept": kept,
        "filtered": filtered
    }

# ------------------ Run ------------------

print("\n=== Extracting PBS soft-clips ===")
pbs_fasta = os.path.join(output_dir, "PBS.softclips.fasta")
pbs_result = extract_softclips(pbs_bam, pbs_fasta, min_clip=min_clip)
summary_metrics.update({
    "PBS_total_pre_filter": pbs_result["kept"] + pbs_result["filtered"],
    "PBS_retained": pbs_result["kept"],
    "PBS_filtered": pbs_result["filtered"]
})

print("=== Extracting Virus soft-clips ===")
virus_fasta = os.path.join(output_dir, "Virus.softclips.fasta")
virus_result = extract_softclips(virus_bam, virus_fasta, min_clip=min_clip)
summary_metrics.update({
    "Virus_total_pre_filter": virus_result["kept"] + virus_result["filtered"],
    "Virus_retained": virus_result["kept"],
    "Virus_filtered": virus_result["filtered"]
})

# ------------------ Build minimap2 index ------------------

mmi_index = os.path.join(output_dir, "PBS.softclips.mmi")
print(f"=== Building minimap2 index: {mmi_index} ===")
subprocess.run([minimap2_path, "-d", mmi_index, pbs_fasta], check=True)

# ------------------ Align Virus to PBS ------------------

sam_out = os.path.join(output_dir, "Virus_vs_PBS.sam")
print("=== Aligning Virus soft-clips to PBS soft-clips ===")
with open(sam_out, "w") as samfile:
    subprocess.run([minimap2_path, "-ax", "map-ont", "-t", str(threads), mmi_index, virus_fasta], stdout=samfile, check=True)

# ------------------ Count Aligned/Unaligned ------------------

print("=== Counting unaligned Virus soft-clips ===")
read_alignment_status = defaultdict(lambda: False)

virus_read_names = set(record.id for record in SeqIO.parse(virus_fasta, "fasta"))
total = len(virus_read_names)

if total > 0:
    with open(sam_out) as f:
        for line in f:
            if line.startswith("@"):
                continue
            fields = line.strip().split("\t")
            read_name = fields[0]
            flag = int(fields[1])
            if not (flag & 0x4):
                read_alignment_status[read_name] = True

    aligned = sum(1 for r in virus_read_names if read_alignment_status[r])
    unaligned = total - aligned

    summary_metrics.update({
        "Virus_total_aligned_to_PBS": aligned,
        "Virus_total_unaligned_to_PBS": unaligned,
        "Virus_total_aligned_pct": round(aligned / total * 100, 2),
        "Virus_total_unaligned_pct": round(unaligned / total * 100, 2)
    })

    print(f"\n[✓] Virus soft-clips aligned to PBS: {aligned} / {total} mapped")
    print(f"[✓] Novel (unaligned) Virus soft-clips: {unaligned} / {total} ({unaligned / total:.2%})")
else:
    summary_metrics.update({
        "Virus_total_aligned_to_PBS": 0,
        "Virus_total_unaligned_to_PBS": 0,
        "Virus_total_aligned_pct": 0.0,
        "Virus_total_unaligned_pct": 0.0
    })
    print("\n[!] No virus soft-clips to align. Skipping alignment stats.")

print("\nAnalysis complete.")

# ------------------ Write Summary CSV ------------------

csv_path = os.path.join(output_dir, "softclip_summary.csv")
with open(csv_path, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["Metric", "Value"])
    for key, value in summary_metrics.items():
        writer.writerow([key, value])

print(f"[📄] Summary CSV written to: {csv_path}")

