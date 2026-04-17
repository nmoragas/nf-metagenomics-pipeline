/*
 * STEP 8 — KrakenTools
 * Per-sample diversity metrics (alpha diversity) and MPA-style output.
 * Uses kreport2mpa.py and alpha_diversity.py from KrakenTools.
 */
process KREPORT2MPA {

    tag "08_KRAKENTOOLS/${sample_id}"

    publishDir "${params.outdir}/08_krakentools/mpa", mode: 'copy'
     
    input:
    tuple val(sample_id), path(bracken_kreport)

    output:
    tuple val(sample_id), path("${sample_id}_mpa.txt"), emit: mpa
    
    script:

    """
    python3 ${projectDir}/bin/kreport2mpa.py \\
    -r ${bracken_kreport}  \\
    -o ${sample_id}_mpa.txt  \\
    --display-header

    """
    stub:
    """
    touch ${sample_id}_mpa.txt
    """
}

process COMBINE_MPA {
    tag "08_KRAKENTOOLS/combine"

    publishDir "${params.outdir}/08_krakentools", mode: 'copy'

    input:
    path(mpa_files)

    output:
    path("combined_species_mpa.txt"),          emit: combined
    path("bracken_abundance_species_mpa.txt"), emit: abundance

    script:
    """
    python3 ${projectDir}/bin/combine_mpa.py \\
        -i ${mpa_files} \\
        -o combined_species_mpa.txt

    grep -E "(s__)|(#Classification)" combined_species_mpa.txt \\
        > bracken_abundance_species_mpa.txt
    """

    stub:
    """
    touch combined_species_mpa.txt
    touch bracken_abundance_species_mpa.txt
    """
}