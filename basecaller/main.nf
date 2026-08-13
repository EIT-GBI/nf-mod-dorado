// ONT rebasecalling from POD5 with Dorado, optionally including modified bases (methylation).
// Output is an UNALIGNED BAM. When params.basecall.modified_bases is set, each
// read carries its methylation calls as MM/ML tags.


process DORADO_BASECALLER {
    tag "${meta.id}"

    publishDir "${params.outdir}/basecalled", mode: 'copy'

    input:
    tuple val(meta), path(pod5)

    output:
    tuple val(meta), path("${meta.id}.dorado.bam"), emit: ubam

    script:
    def args = task.ext.args ?: ''
    def mods = params.basecalling.modified_bases ? "--modified-bases ${params.basecalling.modified_bases}" : ''
    """
    dorado basecaller \\
        ${args} \\
        "${params.basecalling.model}" \\
        "${pod5}" \\
        ${mods} \\
        > ${meta.id}.dorado.bam
    """


    stub:
    """
    touch ${meta.id}.dorado.bam
    """
}
