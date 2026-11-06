// Alignment with dorado aligner (minimap2 inside dorado).
// Writing to a directory with -o makes dorado sort and index the output.

process DORADO_ALIGNER {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), path("${meta.id}.sorted.bam.bai"), emit: bam
    tuple val("${task.process}"), val('dorado'), eval('(command -v dorado >/dev/null && dorado --version 2>&1 || echo unknown) | head -n1'), emit: versions_dorado, topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p aligned
    dorado aligner \\
        ${args} \\
        -t ${task.cpus} \\
        -o aligned \\
        ${fasta} \\
        ${reads}

    mv aligned/*.bam ${meta.id}.sorted.bam
    mv aligned/*.bam.bai ${meta.id}.sorted.bam.bai
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    touch ${meta.id}.sorted.bam.bai
    """
}
