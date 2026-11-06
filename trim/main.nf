// Adapter/primer trimming with dorado trim.
// uBAM (or FASTQ) in, trimmed uBAM out.

process DORADO_TRIM {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.bam"), emit: ubam
    tuple val("${task.process}"), val('dorado'), eval('(command -v dorado >/dev/null && dorado --version 2>&1 || echo unknown) | head -n1'), emit: versions_dorado, topic: versions

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
