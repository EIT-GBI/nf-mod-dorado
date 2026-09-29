// ONT basecalling from POD5 with dorado, optionally including modified bases
// (methylation). Output is an UNALIGNED BAM. When ext.args carries
// --modified-bases, each read carries its modification calls as MM/ML tags.

process DORADO_BASECALLER {
    tag "${meta.id}"

    input:
    tuple val(meta), path(pod5)
    // Model name (e.g. 'sup') or path to a model directory. The image bakes
    // models under /opt/models, e.g. '/opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0'.
    val model

    output:
    tuple val(meta), path("${meta.id}.dorado.bam"), emit: ubam

    script:
    // ext.args goes AFTER the positional arguments, not before them.
    // --modified-bases takes one or more values and consumes every following
    // argument that does not start with '-', so placed before the model it
    // would swallow the model and the POD5 path as modification names.
    def args = task.ext.args ?: ''
    """
    dorado basecaller \\
        "${model}" \\
        "${pod5}" \\
        ${args} \\
        > ${meta.id}.dorado.bam
    """

    stub:
    """
    touch ${meta.id}.dorado.bam
    """
}
