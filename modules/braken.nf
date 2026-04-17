/*
 * STEP 7 — BRAKEN
 * k-mer based taxonomic classification against the BRAKEN database.
 */
process BRACKEN {

    tag "07_BRCKEN/${sample_id}"
     
    publishDir "${params.outdir}/07_bracken", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.log') ? fn : null }

    publishDir "${params.outdir}/07_bracken/reports", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.bracken.kreport') ? fn : null }

    publishDir "${params.outdir}/07_bracken/output", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.bracken') ? fn : null }

    input:
    tuple val(sample_id), path(kraken2_report)

    output:
    tuple val(sample_id), path("${sample_id}.bracken"), emit: output
    tuple val(sample_id), path("${sample_id}.bracken.kreport"), emit: report

    script:
        
    """
    bracken \\
        -d ${params.kraken2_db} \\
        -i ${kraken2_report} \\
        -r ${params.bracken_read_len} \\
        -t ${params.bracken_threshold} \\
        -l ${params.bracken_level} \\
        -o ${sample_id}.bracken \\
        -w ${sample_id}.bracken.kreport \\

    """
    stub:
    """
    touch ${sample_id}.bracken
    touch ${sample_id}.bracken.kreport
    """
}
