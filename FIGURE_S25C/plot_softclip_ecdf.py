#!/usr/bin/env python3

import pysam
import matplotlib.pyplot as plt
import numpy as np
import argparse
import os

def extract_soft_clips(bam_path):
    left_clips = []
    right_clips = []

    with pysam.AlignmentFile(bam_path, "rb") as bam:
        for read in bam:
            if read.is_unmapped or read.cigartuples is None:
                continue

            cigar = read.cigartuples

            # Left soft clip (start of read)
            if cigar[0][0] == 4:
                left_len = cigar[0][1]
            else:
                left_len = 0

            # Right soft clip (end of read)
            if cigar[-1][0] == 4:
                right_len = cigar[-1][1]
            else:
                right_len = 0

            left_clips.append(left_len)
            right_clips.append(right_len)

    return left_clips, right_clips

def plot_ecdf(data, label, color):
    sorted_data = np.sort(data)
    yvals = np.arange(1, len(sorted_data) + 1) / len(sorted_data)
    plt.step(sorted_data, yvals, where="post", label=label, color=color)

def plot_ecdf_distributions(left, right, title_prefix, output_dir, log_scale=False):
    plt.figure(figsize=(8, 5))
    plot_ecdf(left, "Left Soft Clip", "steelblue")
    plot_ecdf(right, "Right Soft Clip", "salmon")

    plt.title(f"{title_prefix} - ECDF of Soft Clip Lengths")
    plt.xlabel("Soft Clip Length (bp)")
    plt.ylabel("Cumulative Fraction of Reads")
    if log_scale:
        plt.xscale("log")
        plt.xlabel("Soft Clip Length (log scale, bp)")
    plt.grid(True, linestyle="--", alpha=0.4)
    plt.legend(loc="lower right")
    plt.tight_layout()

    for ext in ["png", "svg"]:
        out_path = os.path.join(output_dir, f"{title_prefix}_softclip_ecdf.{ext}")
        plt.savefig(out_path)
        print(f"[✓] Saved ECDF plot to {out_path}")

    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Plot ECDFs of soft-clipped base lengths from BAM.")
    parser.add_argument("--bam", required=True, help="Path to BAM file")
    parser.add_argument("--title", required=True, help="Sample name (used in title and filenames)")
    parser.add_argument("--outdir", default=".", help="Directory to save outputs")
    parser.add_argument("--log", action="store_true", help="Use log scale for X-axis")

    args = parser.parse_args()

    left, right = extract_soft_clips(args.bam)
    print(f"[INFO] Extracted soft-clips from {len(left)} reads in {args.bam}")
    plot_ecdf_distributions(left, right, args.title, args.outdir, log_scale=args.log)

if __name__ == "__main__":
    main()

