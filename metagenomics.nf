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
include { FASTQC } from './modules/fastqc.nf'
include { BOWTIE2_HUMAN_REMOVAL } from './modules/remove_human_bowtie2.nf'

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

    // 01. FastQC PRE-alineament     
    FASTQC( ch_reads.map { sample, r1, r2 -> [ "01_pre_fastqc", sample, r1, r2 ] } )

    // 02. Alineament al genoma humà i eliminació 
    BOWTIE2_HUMAN_REMOVAL( ch_reads )



    // 03. Classificació taxonòmica amb Kraken2
    // KRAKEN2( HUMAN_ALIGNMENT.out.reads_clean )
    
    
}

// Executar: nextflow run ../nf-metagenomics-pipeline/metagenomics.nf --input data/raw_data_example/ -profile singularity -resume