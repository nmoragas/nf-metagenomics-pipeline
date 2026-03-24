/*
 * STEP 3 — Clumpify (BBTools)
 * Removes PCR duplicates (and optionally optical duplicates).
* Input: clean reads from BOWTIE2_HUMAN_REMOVAL
 */
process CLUMPIFY_DUPLICATE_REMOVAL {

    tag "03_CLUMPIFY_DUPLICATE_REMOVAL/${sample_id}"
    
    publishDir "${params.outdir}/03_duplicate_removal", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.log') ? fn : null }

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("${sample_id}_deduped_R1.fastq.gz"),
                          path("${sample_id}_deduped_R2.fastq.gz"), emit: reads
    path "${sample_id}_clumpify.log",                               emit: log

    script:
        def mem = task.memory.toGiga() - 2
    """
    clumpify.sh \\
        -Xmx${mem}g \\
        in1=${r1} \\
        in2=${r2} \\
        out1=${sample_id}_deduped_R1.fastq.gz \\
        out2=${sample_id}_deduped_R2.fastq.gz \\
        dedupe \\
        subs=${params.clumpify_subs} \\
        k=${params.clumpify_k} \\
        passes=${params.clumpify_passes} \\
        &> ${sample_id}_clumpify.log
    """
    stub:
    """
    touch ${sample_id}_deduped_R1.fastq.gz ${sample_id}_deduped_R2.fastq.gz
    echo "STUB" > ${sample_id}_clumpify.log
    """
}
