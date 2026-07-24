// ONT rebasecalling from POD5 with Dorado, optionally including modified bases (methylation).
// Output is an UNALIGNED BAM. When params.basecall.modified_bases is set, each
// read carries its methylation calls as MM/ML tags.


process DORADO_BASECALLER {
    tag "${meta.id}"

    publishDir "${params.outdir}/basecalled", mode: 'link'

    input:
    tuple val(meta), path(pod5)

    output:
    tuple val(meta), path("${meta.id}.dorado.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    def mods = params.basecall.modified_bases ? "--modified-bases ${params.basecall.modified_bases}" : ''
    """
    dorado basecaller \\
        ${args} \\
        ${mods} \\
        ${params.basecall.model} \\
        ${pod5} \\
        > ${meta.id}.dorado.bam
    """

    stub:
    """
    touch ${meta.id}.dorado.bam
    """
}
