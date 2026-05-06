# nf-metagenomics-pipeline

A Nextflow pipeline for shotgun metagenomics analysis, covering quality control, host depletion, taxonomic classification, and abundance estimation.

---
     
## Table of Contents 
 
- [Overview](#overview)
- [Pipeline Steps](#pipeline-steps)
- [Requirements](#requirements)
- [Installation](#installation)
- [Databases](#databases)
- [Input](#input)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Authors](#authors)

---

## Overview

`nf-metagenomics-pipeline` processes paired-end shotgun metagenomic reads from raw FASTQ files through quality control, human read removal, duplicate removal, adapter trimming, taxonomic classification with Kraken2, abundance re-estimation with Bracken, and final abundance table generation with KrakenTools.

All steps run in isolated containers (Singularity/Apptainer), ensuring reproducibility across computing environments.

---

## Pipeline Steps

```
fastq.gz
│
├─ [0] SAMPLESHEET_CHECK   ──► Sample list validation
│
├─ [1] FastQC + MultiQC    ──► Pre-processing QC
│
├─ [2] Bowtie2             ──► Human reads removal
│
├─ [3] Clumpify (BBTools)  ──► PCR duplicate removal
│
├─ [4] BBDuk (BBTools)     ──► Adapter trimming + quality filter
│      └─ clean_reads
│
├─ [5] FastQC + MultiQC    ──► Post-processing QC
│
├─ [6] Kraken2             ──► Taxonomic classification
│
├─ [7] Bracken             ──► Abundance re-estimation
│
└─ [8] KrakenTools         ──► Abundance table (MPA format)
```

---

## Requirements

- [Nextflow](https://www.nextflow.io/) ≥ 25.04
- [Singularity](https://sylabs.io/singularity/) or [Apptainer](https://apptainer.org/)
- Access to the required reference databases (see [Databases](#databases))

> All software dependencies are handled automatically via containers. No manual tool installation is required.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_ORG/nf-metagenomics-pipeline.git
```

---

## Databases

The pipeline requires the following reference databases. See the dedicated documentation *(coming soon)* for instructions on how to download and prepare them.

| Database | Used by | Parameter |
|----------|---------|-----------|
| Human genome index (hg38, Bowtie2) | Bowtie2 — human read removal | `--human_db` |
| Kraken2/Bracken database | Kraken2 + Bracken | `--kraken2_db` |

> ⚠️ Paths to these databases must be set in `nextflow.config` or passed as parameters before running the pipeline.

---

## Input

The pipeline takes as input a directory containing paired-end FASTQ files. The directory is scanned recursively, so files can be organized in subdirectories.

**Accepted file extensions:** `.fastq.gz`, `.fq.gz`, `.fastq`, `.fq`

The pipeline is flexible with read pair naming conventions — the following formats are all supported:

- `SAMPLE_R1.fastq.gz` / `SAMPLE_R2.fastq.gz`
- `SAMPLE.R1.fastq.gz` / `SAMPLE.R2.fastq.gz`
- `SAMPLE-R1.fastq.gz` / `SAMPLE-R2.fastq.gz`
- `SAMPLE_1.fastq.gz` / `SAMPLE_2.fastq.gz`
- `SAMPLE.1.fastq.gz` / `SAMPLE.2.fastq.gz`
- `SAMPLE-1.fastq.gz` / `SAMPLE-2.fastq.gz`

The samplesheet is generated automatically by the pipeline at runtime.

---

## Usage

### Standard — local execution with Singularity

Suitable for testing or small datasets on a local machine:

```bash
nextflow run YOUR_ORG/nf-metagenomics-pipeline \
    --input data/raw_data/ \
    -profile standard,singularity
```

### HPC — SLURM execution with Singularity

Recommended for production runs on an HPC cluster:

```bash
nextflow run YOUR_ORG/nf-metagenomics-pipeline \
    --input data/raw_data/ \
    -profile slurm,singularity
```

### HPC — SLURM execution with Apptainer

For HPC environments where Apptainer is available instead of Singularity:

```bash
nextflow run YOUR_ORG/nf-metagenomics-pipeline \
    --input data/raw_data/ \
    -profile slurm,apptainer
```

### Dry-run (stub mode)

Validates the pipeline structure and workflow without executing any real computation. Useful for checking that the pipeline runs correctly before launching a full analysis:

```bash
nextflow run YOUR_ORG/nf-metagenomics-pipeline \
    --input data/raw_data/ \
    -profile standard,singularity \
    -stub
```

### Custom output directory

By default, results are written to `resultats/`. Use `--outdir` to specify a different path:

```bash
nextflow run YOUR_ORG/nf-metagenomics-pipeline \
    --input data/raw_data/ \
    --outdir /path/to/my/results/ \
    -profile slurm,singularity
```

---

## Parameters

All parameters can be set in `nextflow.config` or passed directly on the command line with `--param value`.

### General

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | `null` | Path to directory containing raw FASTQ files |
| `--outdir` | `resultats/` | Output directory |

### Human Read Removal (Bowtie2)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--human_db` | — | Path to hg38 Bowtie2 index |
| `--bowtie2_extra` | `--very-sensitive-local -k 1` | Extra Bowtie2 arguments |


### Duplicate Removal (Clumpify)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--clumpify_subs` | `1` | Substitutions allowed when comparing reads |
| `--clumpify_k` | `11` | K-mer length for duplicate detection |
| `--clumpify_passes` | `3` | Number of passes |

### Adapter Trimming (BBDuk)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--bbduk_k` | `25` | K-mer length for adapter detection |
| `--bbduk_mink` | `6` | Minimum k-mer length at read ends |
| `--bbduk_hdist` | `1` | Mismatches allowed for adapter detection |
| `--bbduk_hdist2` | `0` | Mismatches allowed with short k-mer |
| `--bbduk_trimq` | `20` | Minimum quality for trimming |
| `--bbduk_minlen` | `75` | Minimum read length after trimming |

### Taxonomic Classification (Kraken2)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--kraken2_db` | — | Path to Kraken2/Bracken database |
| `--kraken2_confidence` | `0.0` | Confidence threshold |
| `--kraken2_min_hit_groups` | `2` | Minimum hit groups |

### Abundance Re-estimation (Bracken)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--bracken_read_len` | `150` | Read length used for Bracken |
| `--bracken_threshold` | `10` | Minimum reads threshold |
| `--bracken_level` | `S` | Taxonomic level (`S` = species) |

---

## Output

```
resultats/
├── 01_fastqc_pre/                        # Pre-processing FastQC reports
├── 02_multiqc_pre/                       # Pre-processing MultiQC report
├── 03_bowtie2/                           # Human-depleted reads
├── 04_clumpify/                          # Deduplicated reads
├── 05_bbduk/                             # Trimmed clean reads
├── 06_fastqc_post/                       # Post-processing FastQC reports
├── 07_multiqc_post/                      # Post-processing MultiQC report
├── 07_kraken2/                           # Kraken2 classification reports
├── 07_bracken/
│   ├── reports/                          # Bracken kreports (*.bracken.kreport)
│   └── output/                           # Bracken output (*.bracken)
├── 08_krakentools/
│   ├── mpa/                              # Per-sample MPA files (*_mpa.txt)
│   ├── combined_species_mpa.txt          # All samples combined
│   └── bracken_abundance_species_mpa.txt # Species-level abundance table
└── reports/
    ├── execution_report.html             # Nextflow execution report
    └── timeline.html                     # Nextflow timeline
```

---

## Authors

- **[Núria Moragas]** — [IDIBELL / Oncology Data Analytics Program (PADO)]

---
