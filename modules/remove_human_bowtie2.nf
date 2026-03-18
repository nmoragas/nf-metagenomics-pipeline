#!/usr/bin/env nextflow

/*
 * STEP 1 / 5 — FastQC
 * Reusable module: called twice (pre-trim and post-trim).
 * The `stage` parameter ("pre_trim" | "post_trim") differentiates output dirs.
 */

process FASTQC {
    // nom logs:
    tag "${step}"
    

    // # Es pot utilitzar tant containers generats: 
    // container "${params.sif_dir}/fastqc.sif" 
    // # com de repositori: 
    //container "https://depot.galaxyproject.org/singularity/fastqc:0.11.9--0"

    publishDir "${params.outdir}/${step}/${sample_id}", mode: 'copy'

    input:
    tuple val(step), val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("*.html"), emit: html
    tuple val(sample_id), path("*.zip"),  emit: zip

    script:
"""
fastqc \\
    --threads ${task.cpus} \\
    --outdir . \\
    -- ${r1} ${r2}
"""
}

###################

/*
 * STEP 2 — Bowtie2 Human Read Removal
 * Keeps only UNMAPPED paired reads using --un-conc-gz (no samtools needed).
 * Input: paired-end reads from samplesheet.tsv (sample_id, fastq_1, fastq_2)
 */
process BOWTIE2_HUMAN_REMOVAL {

    tag "02_BOWTIE2_HUMAN_REMOVAL/${sample_id}"
    
    publishDir "${params.outdir}/02_host_removal/${sample_id}", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.log') ? fn : null }

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("${sample_id}_clean_R1.fastq.gz"),
                          path("${sample_id}_clean_R2.fastq.gz"), emit: reads
    path "${sample_id}_bowtie2_human.log",                        emit: log

    script:
        """
        bowtie2 \\
        -p ${task.cpus} \\
        -x ${params.human_db} \\
        -1 ${r1} \\
        -2 ${r2} \\
        ${params.bowtie2_extra} \\
        --un-conc-gz ${sample_id}_clean_R%.fastq.gz \\
        -S /dev/null \\
        2> ${sample_id}_bowtie2_human.log
        """
    stub:
    """
    touch ${sample_id}_clean_R1.fastq.gz ${sample_id}_clean_R2.fastq.gz
    echo "STUB" > ${sample_id}_bowtie2_human.log
    """
}
