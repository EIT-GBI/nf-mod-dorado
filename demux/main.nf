// Barcode demultiplexing with dorado demux: one or more basecalled uBAM in,
// one uBAM per barcode out, plus unclassified.bam.
//
// Classification comes from ext.args: either --kit-name <kit> (classify here),
// or --no-classify to split on the BC tag the basecaller already wrote when it
// ran with --kit-name. --emit-summary adds barcoding_summary.txt (one row per
// read) to the summary output.

process DORADO_DEMUX {
    tag "${meta.id}"

    input:
    // Several BAMs are demultiplexed together, e.g. one per POD5 folder from
    // DORADO_BASECALLER, so reads of one barcode end up in one file.
    tuple val(meta), path(reads, stageAs: 'reads/*')

    output:
    tuple val(meta), path("demux/*.bam"),                 emit: ubam
    tuple val(meta), path("demux/barcoding_summary.txt"), emit: summary, optional: true

    script:
    def args = task.ext.args ?: ''
    """
    dorado demux \\
        --output-dir demux \\
        --threads ${task.cpus} \\
        ${args} \\
        reads
    """

    stub:
    """
    mkdir -p demux
    touch demux/barcode01.bam demux/unclassified.bam
    if [[ "${task.ext.args ?: ''}" == *--emit-summary* ]]; then
        touch demux/barcoding_summary.txt
    fi
    """
}
