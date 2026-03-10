#!/usr/bin/env nextflow

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║         METAGENOMICS SHOTGUN PIPELINE  v2.0                                  ║
║                                                                              ║
║  fastq.gz                                                                    ║
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


// Module INCLUDE statements
include { FASTQC } from './modules/fastqc.nf'


/*
 * Pipeline parameters
 */
params {

    /* 1 config. entrada:  */
        // Primary input - csv amb ruta dels fastq. aparellats. Genració de aquest llistat amb: generate_samplesheet.py
    input: Path

    test {
        params.input = "${projectDir}/data/samplesheet.csv"
            }

    // fastqc container
    sif_dir = "./sif"
    
 
    // Reference genome archive
    hisat2_index_zip: Path

    // Report ID
    report_id: String
}

singularity {
    enabled    = true
    autoMounts = true
}

workflow {

    main:
    // Create input channel from the contents of a CSV file (samplesheet.csv)
    read_ch = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> file(row.fastq_path) }

    // Initial quality control
    FASTQC(read_ch)

    // Adapter trimming and post-trimming QC
    

    // Alignment to a reference genome
    

    // Comprehensive QC report generation
    
    // Declarar SORTIDES a la secció:
    publish:
    fastqc_zip = FASTQC.out.zip
    fastqc_html = FASTQC.out.html

}


// on es publica resultat cadascuna de les seccions. 
output {
    fastqc_zip {
        path 'fastqc'
    }
    fastqc_html {
        path 'fastqc'
    }


// Executar: nextflow run metagenomics.nf -profile test -> teoricament sortida a results/fastqc