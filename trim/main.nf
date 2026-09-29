// Adapter/primer trimming with dorado trim.
// uBAM (or FASTQ) in, trimmed uBAM out.

process DORADO_TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.bam"), emit: ubam

    script:
    def args = task.ext.args ?: ''
    """
    dorado trim \\
        ${args} \\
        ${reads} \\
        > ${meta.id}.trimmed.bam
    """

    stub:
    """
    touch ${meta.id}.trimmed.bam
    """
}
