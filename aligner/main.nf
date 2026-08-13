// Alignment with Dorado's minimap2

process DORADO_ALIGNER {
    tag "${meta.id}"

    publishDir "${params.outdir}/aligned", mode: 'copy'

    input: 
    tuple val(meta), path(reads)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), path("${meta.id}.sorted.bam.bai"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    dorado aligner \\
        ${args} \\
        -t ${task.cpus} \\
        ${fasta} \\
        ${reads} \\
        > ${meta.id}.sorted.bam
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    touch ${meta.id}.sorted.bam.bai
    """
}