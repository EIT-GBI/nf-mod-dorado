# nf-mod-dorado

Nextflow module for [dorado](https://github.com/nanoporetech/dorado) (ONT
basecalling, adapter trimming and alignment). Used as a git submodule by
pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-dorado:v0.0.0`

Published for `linux/amd64` only — the dorado tarball is `linux-x64` and the
base is a CUDA image, so an arm64 build would carry an x86_64 binary. On an
arm64 host, run with `docker.runOptions = '--platform=linux/amd64'`.

## Processes

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `DORADO_BASECALLER` | `basecaller/main.nf` | `tuple val(meta), path(pod5)` | `ubam` |
| `DORADO_TRIM` | `trim/main.nf` | `tuple val(meta), path(reads)` | `ubam` |
| `DORADO_ALIGNER` | `aligner/main.nf` | `tuple val(meta), path(reads)`, `tuple path(fasta), path(fai)` | `bam` |

`DORADO_ALIGNER` emits `tuple val(meta), path(bam), path(bai)` — it sorts and
indexes in the same task.

## GPU requirements

Only `DORADO_BASECALLER` needs a GPU. `DORADO_TRIM` and `DORADO_ALIGNER` are
CPU work — the aligner wraps minimap2 — so they do not need `--nv`, a GPU queue
or an accelerator request. Scheduling them onto GPU nodes reserves hardware they
never use.

The image itself is CUDA-based regardless, because the three subtools ship as
one binary. It is several GB, which matters when a CI run pulls it only to
align.

```groovy
process {
    withName: DORADO_BASECALLER {
        accelerator      = 1
        clusterOptions   = '--gres=gpu:1'   // keep count == accelerator
        containerOptions = '--nv'
        queue            = 'gpu'
    }
}
```

## Basecalling models

The image bakes simplex and modified-base models into `/opt/models`, so a POD5
run works offline. Point at the simplex model's path; the sibling modification
models are picked up automatically when `--modified-bases` is set.

```groovy
params.basecalling.model = '/opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0'
```

## Publishing

These processes publish under `${params.outdir}` (`basecalled/`, `trimmed/`,
`aligned/`). Pipelines that want a different layout override `publishDir` with
a `withName` selector.

## Tool arguments

Flags are passed through `task.ext.args` rather than read from pipeline
`params`, so the module never depends on a particular pipeline's parameter
names:

```groovy
process {
    withName: DORADO_ALIGNER {
        ext.args = '--mm2-opts "-y"'
    }
}
```

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-dorado.git modules/dorado
git -C modules/dorado checkout v0.0.0
```

Then include the module's container config from your `nextflow.config`. Nextflow
does not read a submodule's config on its own, so without this line the
processes have no image:

```groovy
includeConfig 'modules/dorado/conf/module.config'
```

`conf/module.config` pins the image to the version built from this same commit,
and carries no `manifest {}` block, so it will not overwrite your pipeline's
own manifest. Override it in your pipeline with a `withName` selector if needed.

And include the processes:

```groovy
include { DORADO_BASECALLER } from './modules/dorado/basecaller/main.nf'
include { DORADO_TRIM } from './modules/dorado/trim/main.nf'
include { DORADO_ALIGNER } from './modules/dorado/aligner/main.nf'
```

## Requirements

Nextflow 26.04.4 or newer. A CUDA-capable GPU for `DORADO_BASECALLER` only.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
