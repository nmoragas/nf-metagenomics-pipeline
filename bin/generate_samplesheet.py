#!/usr/bin/env python3
"""
generate_samplesheet.py

Objective:
Scans a directory for fastq.gz files and auto-generates the pipeline CSV sample sheet. Two columns:
    - sample_ID
    - fastq_path

Usage:
    python bin/generate_samplesheet.py --input /path/to/fastqs/
    python bin/generate_samplesheet.py --input /path/to/fastqs/ --output my_samples.tsv
    python bin/generate_samplesheet.py --input /path/to/fastqs/ --single-end
    
    python bin/generate_samplesheet.py --input /data/raw_exemple/ --output samplesheet.tsv
"""



# 0 import librarys
#-------------------------------------------------------------------------
## totes llibraries std de python.
import argparse # Llegir arguments linea comandaments. -- input, -- output, --single-end
import re # Permet treballar amb expressions regulars per cercar i manipular patrons en cadenes de text. Detecció fw / rv. Neteja nom de fitxers.
import sys # Accés a funcions i variables del propi intèrpret de Python. Sortir amb errors (sys.exit) i escriu a stderr
from pathlib import Path # Cerca els FASTQ i manipula rutes


# 1 Patrons d'expressio regulars.
#-------------------------------------------------------------------------
R1_PAT = re.compile(r'[_\.]R1[_\.]|_1\.fastq|[_\.]R1\.fastq', re.IGNORECASE)
R2_PAT = re.compile(r'[_\.]R2[_\.]|_2\.fastq|[_\.]R2\.fastq', re.IGNORECASE)

SUFFIXES = re.compile(
    r'(_S\d+)?(_L\d+)?(_R[12])?(_\d{3})?(\.(fastq|fq)(\.gz)?)$',
    re.IGNORECASE
)


def clean_id(filename):
    return SUFFIXES.sub('', filename)


def find_fastqs(directory):
    exts = ('*.fastq.gz', '*.fq.gz', '*.fastq', '*.fq')
    files = []
    for ext in exts:
        files.extend(Path(directory).rglob(ext))
    return sorted(set(files))


def build_pairs(files):
    r1s = [f for f in files if R1_PAT.search(f.name)]
    r2s = [f for f in files if R2_PAT.search(f.name)]

    pairs = {}
    for r1 in r1s:
        sid = clean_id(R1_PAT.sub('', r1.name))
        r2_match = next(
            (r2 for r2 in r2s
             if clean_id(R2_PAT.sub('', r2.name)) == sid
             and r2.parent == r1.parent),
            None
        )
        pairs[sid] = (str(r1.resolve()), str(r2_match.resolve()) if r2_match else None)
    return pairs


def build_singles(files):
    singles = {}
    for f in files:
        sid = clean_id(f.name)
        singles[sid] = str(f.resolve())
    return singles


def main():
    parser = argparse.ArgumentParser(
        description="Generate a TSV sample sheet for the metagenomics Nextflow pipeline.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--input',      required=True,               help="Directory with fastq.gz files")
    parser.add_argument('--output',     default='samplesheet.tsv',   help="Output TSV (default: samplesheet.tsv)")
    parser.add_argument('--single-end', action='store_true',         help="Single-end reads (default: paired-end)")
    args = parser.parse_args()

    if not Path(args.input).is_dir():
        sys.exit(f"ERROR: '{args.input}' is not a directory.")

    all_files = find_fastqs(args.input)
    if not all_files:
        sys.exit(f"ERROR: No fastq.gz files found in '{args.input}'.")

    print(f"Found {len(all_files)} fastq file(s) in {args.input}", file=sys.stderr)

    rows = []
    if args.single_end:
        samples = build_singles(all_files)
        header  = "sample_id\tfastq_r1\n"
        for sid, r1 in sorted(samples.items()):
            rows.append(f"{sid}\t{r1}\n")
    else:
        samples = build_pairs(all_files)
        header  = "sample_id\tfastq_r1\tfastq_r2\n"
        for sid, (r1, r2) in sorted(samples.items()):
            if r2 is None:
                print(f"  WARNING: No R2 found for '{sid}' — skipping.", file=sys.stderr)
                continue
            rows.append(f"{sid}\t{r1}\t{r2}\n")

    with open(args.output, 'w') as fh:
        fh.write(header)
        fh.writelines(rows)

    print(f"\nSample sheet written → {args.output}  ({len(rows)} sample(s))")
    for r in rows:
        fields = r.strip().split('\t')
        print(f"  {fields[0]}")


if __name__ == '__main__':
    main()



