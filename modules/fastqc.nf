#!/usr/bin/env nextflow

/*
 * STEP 1 / 5 — FastQC
 * Reusable module: called twice (pre-trim and post-trim).
 * The `stage` parameter ("pre_trim" | "post_trim") differentiates output dirs.
 */

process FASTQC {

    # Es pot utilitzar tant containers generats: 
    container "${params.sif_dir}/fastqc.sif"
    # com de repositori: 
    # container "docker://biocontainers/fastqc:v0.11.9_cv8"


    input:
    path reads

    output:
    path "${reads.simpleName}_fastqc.zip", emit: zip
    path "${reads.simpleName}_fastqc.html", emit: html

    script:
        """
        fastqc \\
            --t ${task.cpus}\\
            --outdir .\\
            ${reads}
        """
}
