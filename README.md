# nf-metagenomics-pipeline

A Nextflow pipeline for shotgun metagenomics analysis, covering quality control, host depletion, taxonomic classification, and abundance estimation.

---

## Table of Contents

- [Overview](#overview)
- [Pipeline Steps](#pipeline-steps)
- [Requirements](#requirements)
- [Installation](#installation)
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
- Access to the reference databases (see [Parameters](#parameters)):
  - Human genome index (Bowtie2, hg38)
  - Kraken2/Bracken database

> All software dependencies are handled automatically via containers. No manual tool installation is required.

---

## Installation

```bash
git clone https://github.com/YOUR_ORG/nf-metagenomics-pipeline.git
cd nf-metagenomics-pipeline
```

---

## Input

The pipeline requires a **samplesheet CSV** file with the following format:

```csv
sample,fastq_1,fastq_2
SAMPLE_01,/path/to/SAMPLE_01_R1.fastq.gz,/path/to/SAMPLE_01_R2.fastq.gz
SAMPLE_02,/path/to/SAMPLE_02_R1.fastq.gz,/path/to/SAMPLE_02_R2.fastq.gz
```

| Column    | Description                        |
|-----------|------------------------------------|
| `sample`  | Unique sample identifier           |
| `fastq_1` | Absolute path to R1 FASTQ file     |
| `fastq_2` | Absolute path to R2 FASTQ file     |

---

## Usage

**Local execution with Singularity:**
```bash
nextflow run main.nf \
    -profile standard,singularity \
    --input samplesheet.csv \
    --outdir results/
```

**HPC execution with SLURM and Apptainer:**
```bash
nextflow run main.nf \
    -profile slurm,apptainer \
    --input samplesheet.csv \
    --outdir results/
```

**Dry-run (stub mode):**
```bash
nextflow run main.nf \
    -profile standard,singularity \
    --input samplesheet.csv \
    --outdir results/ \
    -stub
```

---

## Parameters

All parameters can be set in `nextflow.config` or passed directly on the command line with `--param value`.

### General

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | `null` | Path to samplesheet CSV |
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
├── 01_fastqc_pre/          # Pre-processing FastQC reports
├── 02_multiqc_pre/         # Pre-processing MultiQC report
├── 03_bowtie2/             # Human-depleted reads
├── 04_clumpify/            # Deduplicated reads
├── 05_bbduk/               # Trimmed clean reads
├── 06_fastqc_post/         # Post-processing FastQC reports
├── 07_multiqc_post/        # Post-processing MultiQC report
├── 07_kraken2/             # Kraken2 classification reports
├── 07_bracken/
│   ├── reports/            # Bracken kreports (*.bracken.kreport)
│   └── output/             # Bracken output (*.bracken)
├── 08_krakentools/
│   ├── mpa/                # Per-sample MPA files
│   ├── combined_species_mpa.txt
│   └── bracken_abundance_species_mpa.txt
└── reports/
    ├── execution_report.html
    └── timeline.html
```

---

## Authors

- **[Author names]** — [Institution / Research Group]

---
