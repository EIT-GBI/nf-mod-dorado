process __NAME_UPPER__ {
    // tag "${meta.id}"

    input:
    // TODO: declare inputs, e.g. tuple val(meta), path(reads)

    output:
    // TODO: declare outputs, e.g. tuple val(meta), path("*.out"), emit: out

    script:
    def args = task.ext.args ?: ''
    """
    # TODO: __NAME__ command
    """
}
