/*
 * STEP 6 — KRAKEN2
 * k-mer based taxonomic classification against the Kraken2 database.
 */
process KRAKEN2 {

    tag "06_KRAKEN2/${sample_id}"
     
    publishDir "${params.outdir}/06_kraken2", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.log') ? fn : null }

    publishDir "${params.outdir}/06_kraken2/reports", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.kraken2.report') ? fn : null }

    publishDir "${params.outdir}/06_kraken2/output", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.kraken2.output') ? fn : null }

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("${sample_id}.kraken2.report"), emit: report
    tuple val(sample_id), path("${sample_id}.kraken2.output"), emit: output

    script:
        
    """
    kraken2 \\
        --db ${params.kraken2_db} \\
        --threads ${task.cpus} \\
        --use-names \\
        --confidence ${params.kraken2_confidence} \\
        --report ${sample_id}.kraken2.report \\
        --output ${sample_id}.kraken2.output \\
        --paired ${r1} ${r2}

    """
    stub:
    """
    touch ${sample_id}.kraken2.output
    touch ${sample_id}.kraken2.report
    """
}
