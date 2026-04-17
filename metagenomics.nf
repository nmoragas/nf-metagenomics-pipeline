#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║         METAGENOMICS SHOTGUN PIPELINE  v2.0                                  ║
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
║    │      │                                                                  ║
║    │      └─ [4] clean_reads                                                 ║
║    │                                                                         ║
║    ├─ [5] FastQC + MultiQC  ──► Post-processing QC                           ║
║    │                                                                         ║
║    ├─ [6] Kraken2  ──► Taxonomic classification                              ║
║    │                                                                         ║
║    ├─ [7] Bracken  ──► Abundance re-estimation                               ║
║    │                                                                         ║
║    └─ [8] KrakenTools  ──► Alpha diversity + Abundance table                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

// ── Importar mòduls ───────────────────────────────────────────────────────────
include { SAMPLESHEET_CHECK } from './modules/sampleSheet_check.nf'
include { FASTQC as FASTQC_PRE } from './modules/fastqc.nf'
include { MULTIQC as MULTIQC_PRE  } from './modules/multiqc.nf'
include { BOWTIE2_HUMAN_REMOVAL } from './modules/remove_human_bowtie2.nf'
include { CLUMPIFY_DUPLICATE_REMOVAL } from './modules/clumpify_duplicate_removal.nf'
include { BBDUK_TRIMMING } from './modules/bbduck_adapter_trimming.nf'
include { FASTQC as FASTQC_POST } from './modules/fastqc.nf'
include { MULTIQC as MULTIQC_POST } from './modules/multiqc.nf'
include { KRAKEN2 } from './modules/kraken2.nf'
include { BRACKEN } from './modules/braken.nf'
include { KREPORT2MPA } from './modules/krakentools.nf'
include { COMBINE_MPA  } from './modules/krakentools.nf'


// ── Paràmetres per defecte ──────────────────────────────
params.input  = null
params.outdir = "${launchDir}/resultats"


// ── Validació entrada ──────────────────────────────────────
if (!params.input)      error "ERROR: --input és obligatori (directori amb fastq.gz)"




// ── Workflow ──────────────────────────────────────────────────────────────────
workflow {
    
    main:
    // 00. Generar samplesheet automàticament
    ch_input_dir = Channel.fromPath( file(params.input).toAbsolutePath().toString() )
    SAMPLESHEET_CHECK( ch_input_dir )

    
    // Llegir TSV i separar columnes   
    ch_reads = SAMPLESHEET_CHECK.out.samplesheet
    .splitCsv( header: true, sep: '\t' )
    .map { row -> 
        def sample = row.sample_id.replaceAll(/^-/, '')  // elimina - inicial
        [ sample, file(row.fastq_r1), file(row.fastq_r2) ] 
    }

    // 01. FastQC + MULTIQC PRE-alineament     
    FASTQC_PRE( ch_reads.map { sample, r1, r2 -> [ "01_pre_fastqc", sample, r1, r2 ] } )
    MULTIQC_PRE(
    FASTQC_PRE.out.zip
        .map { sample, zips -> zips }
        .collect()
        .map { zips -> [ "01_pre_fastqc", zips ] }
    )

    // 02. Alineament al genoma humà i eliminació 
    BOWTIE2_HUMAN_REMOVAL( ch_reads )

    // 03. Removes PCR duplicates amb clumpify
    CLUMPIFY_DUPLICATE_REMOVAL( BOWTIE2_HUMAN_REMOVAL.out.reads )

    // 04. Adapter trimming + quality filter
    BBDUK_TRIMMING( CLUMPIFY_DUPLICATE_REMOVAL.out.reads )

    // 05. FastQC POST + MultiQC POST
    FASTQC_POST( BBDUK_TRIMMING.out.reads.map { sample, r1, r2 -> [ "05_post_fastqc", sample, r1, r2 ] } )
    MULTIQC_POST(
    FASTQC_POST.out.zip
        .map { sample, zips -> zips }
        .collect()
        .map { zips -> [ "05_post_fastqc", zips ] }
    )

    // 06. Classificació taxonòmica amb Kraken2
    KRAKEN2( BBDUK_TRIMMING.out.reads )

    // 07. Bracken abundance re-estimation
    BRACKEN( KRAKEN2.out.report) 

    KREPORT2MPA(BRACKEN.out.report)
    mpa_collected = KREPORT2MPA.out.mpa
        .map { sample_id, mpa_file -> mpa_file }
        .collect()

    COMBINE_MPA(mpa_collected) 

}

// Executar: 
// module load apps/nextflow/25.04.6
// nextflow run ../nf-metagenomics-pipeline/metagenomics.nf --input data/raw_data_example/ -profile singularity,slurm
// nextflow run ../nf-metagenomics-pipeline/metagenomics.nf --input data/raw_data_example/ -profile apptainer,slurm -resume