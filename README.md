# 🧬 NF - Metagenomics Shotgun Pipeline v1.0

> [!WARNING]
> 🚧 **Pipeline en construcció — No finalitzat** 🚧
> Aquest pipeline està actualment en desenvolupament actiu. Pot contenir errors i canvis importants sense avís previ.

## Introduction

**nf-metagenomics-pipeline** is a bioinformatics analysis pipeline for assembly, binning and annotation of metagenomes from FASTQ to abundance table.


**ON GOING DEVELOPMENT**

## Flux complet

```
╔══════════════════════════════════════════════════════════════════════════════╗
║         METAGENOMICS SHOTGUN PIPELINE  v1.0                                  ║
║                                                                              ║
║  fastq.gz                                                                    ║
║    │                                                                         ║
║    ├─ [0] SAMPLESHEET_CHECK  ──► generacio llistat mostres                   ║
║    │                                                                         ║
║    ├─ [1] FastQC + MultiQC  ──► Pre-processing QC                            ║
║    │                                                                         ║
║    ├─ [2] Bowtie2  ──► Human reads removal                                   ║
║    │                                                                         ║
║    ├─ [3] Clumpify (BBTools)  ──► PCR duplicate removal                      ║
║    │                                                                         ║
║    ├─ [4] BBDuk (BBTools)  ──► Adapter trimming + quality filter             ║
║    │                                                                         ║
║    ├─ [5] FastQC + MultiQC  ──► Post-processing QC                           ║
║    │                                                                         ║
║    ├─ [6] Kraken2  ──► Taxonomic classification                              ║
║    │                                                                         ║
║    ├─ [7] Bracken  ──► Abundance re-estimation                               ║
║    │                                                                         ║
║    └─ [8] KrakenTools  ──► Alpha diversity + Abundance table                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

```

## Contenidors Singularity (un per pas)

| Pas | Contenidor | Eines |
|-----|-----------|-------|
| Host removal | `bowtie2.sif` | Bowtie2 2.5.3 + Samtools 1.19 |
| FastQC pre/post | `fastqc.sif` | FastQC 0.12.1 |
| MultiQC pre/post | `multiqc.sif` | MultiQC 1.21 |
| Deduplication | `bbtools.sif` | BBTools 39.06 (Clumpify) |
| Trimming | `bbtools.sif` | BBTools 39.06 (BBDuk) |
| Classification | `kraken2.sif` | Kraken2 2.1.3 |
| Abundance | `bracken.sif` | Bracken 2.9 |
| Diversity | `krakentools.sif` | KrakenTools 1.2 + pandas |

---

## 🚀 Posada en marxa

### 1. Construir els contenidors Singularity

```bash
# Com a root:
sudo bash containers/build_containers.sh

# Sense root (fakeroot, recomanat en HPC):
bash containers/build_containers.sh --fakeroot
```

Els fitxers `.sif` es creen a `containers/`.

### 2. Generar el sample sheet

```bash
# Paired-end (per defecte):
python bin/generate_samplesheet.py \
    --input /path/to/fastqs/ \
    --output samplesheet.tsv

```

El sample sheet resultant:
```
sample_id       fastq_r1                          fastq_r2
sample_A        /data/sample_A_R1_001.fastq.gz    /data/sample_A_R2_001.fastq.gz
sample_B        /data/sample_B_R1_001.fastq.gz    /data/sample_B_R2_001.fastq.gz
```

### 3. Executar el pipeline

```bash
 module load apps/nextflow/25.04.6

# Singularity en local:
nextflow run main.nf \
    -profile singularity \
    --samples samplesheet.tsv \
    --kraken2_db /databases/kraken2_standard \
    --human_db   /databases/bowtie2/hg38/hg38

# Singularity + SLURM (HPC):
nextflow run main.nf \
    -profile singularity,slurm \
    --samples samplesheet.tsv \
    --kraken2_db /databases/kraken2_standard \
    --human_db   /databases/bowtie2/hg38/hg38 \
    --outdir     results

# Reprendre una execució interrompuda:
nextflow run main.nf -resume [resta de paràmetres]

# Executar directament des de GitHub:
nextflow run github.com/grup/metagenomics-pipeline \
    -profile singularity,slurm \
    -r v1.0 \
    --input /data/fastqs/ \
    ##--samples samplesheet.tsv \
    --kraken2_db /databases/kraken2_standard \
    --human_db /databases/bowtie2/hg38 \
    --outdir ./results


```

---

## ⚙️ Paràmetres principals

| Paràmetre | Default | Descripció |
|-----------|---------|------------|
| `--samples` | **obligatori** | Path al TSV de mostres |
| `--kraken2_db` | **obligatori** | Directori de la base de dades Kraken2 |
| `--human_db` | **obligatori** | Prefix índex Bowtie2 del genoma humà |
| `--outdir` | `results` | Directori de sortida |
| `--paired` | `true` | `true` = paired-end, `false` = single-end |
| `--bracken_level` | `S` | `S`=espècie, `G`=gènere, `F`=família |
| `--bracken_read_len` | `150` | Longitud de lectura per Bracken |
| `--bracken_threshold` | `10` | Reads mínims per incloure un tàxon |
| `--bbduk_trimq` | `20` | Qualitat mínima de trimming |
| `--bbduk_minlen` | `50` | Longitud mínima post-trim |
| `--clumpify_optical` | `true` | Eliminar duplicats òptics |
| `--kraken2_confidence` | `0.0` | Llindar de confiança (0–1) |

---
## ⚙️ Configuració avançada — `nextflow.config`

Els paràmetres del pipeline es poden modificar directament al fitxer `nextflow.config` sense tocar els mòduls.

### Bowtie2 — Human Read Removal
```groovy
// Ruta a l'índex bowtie2 del genoma humà (hg38)
params.human_db = "/mnt/typhon/references/human/hg38/ncbi/indexes/bowtie2/genome"

// Flags addicionals de bowtie2 per a l'eliminació de reads humanes.
//
// Mode d'alineament (de menys a més sensible):
//   --very-fast-local | --fast-local | --sensitive-local | --very-sensitive-local
//   --very-fast       | --fast       | --sensitive       | --very-sensitive
//   Recomanat: --very-sensitive-local (captura reads humanes degradades o amb adaptadors)
//
// Control de parelles:
//   --no-mixed       evita alinear una read de forma independent si la parella no alinia
//   --no-discordant  descarta alineaments on les dues reads apunten en direcció inesperada
//   Recomanat: afegir ambdós per mantenir la integritat de les parelles
//
// Nombre d'alineaments reportats:
//   -k 1  reporta només el primer alineament trobat (suficient per a host removal, més ràpid)
//
params.bowtie2_extra = "--very-sensitive-local --no-mixed --no-discordant -k 1"
```

> Els valors del `nextflow.config` es poden sobreescriure puntuals des de la línia de comandes:
> ```bash
> nextflow run main.nf --bowtie2_extra "--sensitive-local --no-mixed --no-discordant -k 1"
> ```

## 📦 Bases de dades necessàries

### Kraken2 + Bracken (obligatòria)
```bash
# Descarregar pre-construïda (~60 GB, recomanat):
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20240112.tar.gz
mkdir -p /databases/kraken2_standard
tar -xzf k2_standard_20240112.tar.gz -C /databases/kraken2_standard/

# Construir index Bracken (necessari!):
bracken-build -d /databases/kraken2_standard -t 16 -l 150

# O construir la DB des de zero:
kraken2-build --standard --db /databases/kraken2_standard --threads 16
```

### Genoma humà per Bowtie2 (obligatori)
```bash
# Descarregar índex pre-construït GRCh38:
wget https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip
unzip GRCh38_noalt_as.zip -d /databases/bowtie2/

# Usa --human_db /databases/bowtie2/GRCh38_noalt_as/GRCh38_noalt_as
```

---

## 📊 Estructura de sortides

```
results/
├── 01_host_removal/
│   └── {sample}/          # Reads nets (sense human), log Bowtie2
├── qc/
│   ├── pre_trim/
│   │   ├── {sample}/      # FastQC reports post host-removal, pre-trim
│   │   └── multiqc/       # MultiQC agregat pre-trim
│   └── post_trim/
│       ├── {sample}/      # FastQC reports post-trim
│       └── multiqc/       # MultiQC agregat post-trim
├── 02_clumpify/
│   └── {sample}/          # Log Clumpify (duplicats eliminats)
├── 03_bbduk/
│   └── {sample}/          # Log BBDuk (adaptadors, qualitat)
├── 04_kraken2/
│   └── {sample}/
│       ├── *.kraken2.report
│       └── *.kraken2.output
├── 05_bracken/
│   └── {sample}/
│       ├── *.bracken
│       └── *_bracken.kreport
├── 06_krakentools/
│   └── {sample}/
│       ├── *_alpha_diversity.txt   # Shannon, Simpson, Fisher, BP
│       └── *.mpa                   # MetaPhlAn-style output
├── 07_abundance_table/
│   ├── abundance_counts_S.tsv       # Comptes absoluts (taxa × mostres)
│   ├── abundance_relative_S.tsv     # Abundàncies relatives
│   └── alpha_diversity_all_samples.tsv
└── pipeline_info/
    ├── timeline.html
    ├── report.html
    ├── trace.txt
    └── dag.html
```

---

## 🛠️ Requisits del sistema

- **Nextflow** ≥ 23.10
- **Singularity** ≥ 3.8 (o Apptainer ≥ 1.0)
- **RAM**: mínim 64 GB (Kraken2 DB estàndard ~60 GB en RAM)
- **Disk**: ~100 GB per a la DB Kraken2 + espai per als resultats

```bash
# Instal·lar Nextflow:
curl -s https://get.nextflow.io | bash
mv nextflow /usr/local/bin/
```


