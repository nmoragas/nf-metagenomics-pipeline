/*
 * STEP 4 — BBDuk Adapter Trimming + Quality Filter
 * Removes adapters, artifacts and low quality bases.
 * Input: deduplicated reads from CLUMPIFY_DEDUP
 */
process BBDUK_TRIMMING {

    tag "04_BBDUK_TRIMMING/${sample_id}"
    
    publishDir "${params.outdir}/04_bbduk_trim", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.log') ? fn : null }

    publishDir "${params.outdir}/05_clean_reads", mode: 'copy',
        saveAs: { fn -> fn.endsWith('.fastq.gz') ? fn : null }

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), path("${sample_id}_clean_R1.fastq.gz"),
                          path("${sample_id}_clean_R2.fastq.gz"), emit: reads
    path "${sample_id}_bbduk.log",                                emit: log
    path "${sample_id}_adapters.txt",                             emit: stats

    script:
        def mem = task.memory.toGiga() - 2
    """
    bbduk.sh \\
        -Xmx${mem}g \\
        in1=${r1} \\
        in2=${r2} \\
        out1=${sample_id}_clean_R1.fastq.gz \\
        out2=${sample_id}_clean_R2.fastq.gz \\
        ref=adapters,artifacts,phix \\
        k=${params.bbduk_k} \\
        mink=${params.bbduk_mink} \\
        hdist=${params.bbduk_hdist} \\
        hdist2=${params.bbduk_hdist2} \\
        ktrim=r \\
        qtrim=rl \\
        trimq=${params.bbduk_trimq} \\
        minlength=${params.bbduk_minlen} \\
        stats=${sample_id}_adapters.txt \\
        &> ${sample_id}_bbduk.log
    """
    stub:
    """
    touch ${sample_id}_clean_R1.fastq.gz ${sample_id}_clean_R2.fastq.gz
    touch ${sample_id}_adapters.txt
    echo "STUB" > ${sample_id}_bbduk.log
    """
}
