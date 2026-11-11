# nf-mod-dorado

Nextflow module for [dorado](https://github.com/nanoporetech/dorado), Oxford
Nanopore's basecaller, demultiplexer, read trimmer and aligner. Used as a git submodule by
pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-dorado:v1.0.0`

The image carries dorado 0.8.3 on the NVIDIA CUDA 12.4.1 runtime (Ubuntu 22.04),
published for `linux/amd64` only (the release build has no room for both
architectures on a standard runner; the Dockerfile still builds `linux/arm64`
locally). **The image carries the sup
(highest-accuracy) models only**, baked in under `/opt/models`:

| Model | Modified-base models baked in beside it |
| --- | --- |
| `dna_r10.4.1_e8.2_400bps_sup@v5.0.0` | `5mCG_5hmCG@v2.0.1`, `6mA@v2`, `4mC_5mC@v2` |

No hac or fast model is baked in. dorado can still download one by name at run
time (e.g. `model = 'hac'`), which needs internet access from the compute node.

## Processes

Each subtool lives in its own folder (nf-core style), with a `main.nf`, a
`meta.yml` and an nf-test case under `tests/`.

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `DORADO_BASECALLER` | `basecaller/main.nf` | `tuple val(meta), path(pod5)`<br>`val model` | `ubam` |
| `DORADO_DEMUX` | `demux/main.nf` | `tuple val(meta), path(reads)` | `ubam`, `summary` |
| `DORADO_TRIM` | `trim/main.nf` | `tuple val(meta), path(reads)` | `ubam` |
| `DORADO_ALIGNER` | `aligner/main.nf` | `tuple val(meta), path(reads)`<br>`tuple path(fasta), path(fai)` | `bam` |

- `DORADO_BASECALLER` basecalls a POD5 file or directory to an unaligned BAM,
  `<meta.id>.dorado.bam`. `model` is dorado's required positional model
  argument: normally the baked-in sup model,
  `/opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0`, or a name dorado resolves
  and downloads itself (e.g. `sup@v5.0.0`).
- `DORADO_DEMUX` splits one or more basecalled reads files by barcode into
  `demux/<kit>_<barcode>.bam` plus `demux/unclassified.bam`. Pass either
  `--kit-name <kit>` (classify here) or `--no-classify` (split on the `BC` tag
  the basecaller wrote when run with `--kit-name`) through `ext.args`.
  `--emit-summary` adds `demux/barcoding_summary.txt` on the `summary` output.
- `DORADO_TRIM` trims adapters and primers from basecalled reads (uBAM or
  FASTQ), emitting the unaligned BAM `<meta.id>.trimmed.bam`.
- `DORADO_ALIGNER` aligns basecalled reads (uBAM or FASTQ) to the reference and
  emits `[meta, <meta.id>.sorted.bam, <meta.id>.sorted.bam.bai]`, coordinate
  sorted and indexed. Read tags such as MM/ML are carried through.

## Publishing

These processes do **not** publish their own outputs. Publishing is the
consuming pipeline's job, via a workflow `output {}` block. This keeps the
module reusable across pipelines that want different result layouts.

## Tool arguments

Flags are passed through `task.ext.args` rather than read from pipeline
`params`, so the module never depends on a particular pipeline's parameter
names. What dorado requires, such as the basecalling model, is an explicit
input instead.

Modified-base calling is requested this way:

```groovy
process {
    withName: DORADO_BASECALLER {
        ext.args = '--models-directory /opt/models --modified-bases 5mCG_5hmCG'
    }
}
```

Two things about that line are load-bearing:

- **`--models-directory /opt/models`.** dorado 0.8.3 does not look for the
  modified-base model next to the simplex model path. It looks in
  `--models-directory`, which defaults to the task's working directory, and
  otherwise downloads the model. Without the flag every task re-downloads the
  model, and fails where the compute node has no internet access.
- **The module places `ext.args` after the model and POD5 arguments.**
  `--modified-bases` takes one or more values and consumes every following
  argument that does not start with `-`, so placed before the positionals it
  would swallow the model path. Several modifications can be listed
  (`--modified-bases 5mCG_5hmCG 6mA`). The sup modified-base models baked in are
  `5mCG_5hmCG`, `6mA` and `4mC_5mC`.

Other examples:

```groovy
process {
    withName: DORADO_BASECALLER {
        ext.args = '--min-qscore 10'
    }
    withName: DORADO_TRIM {
        ext.args = '--no-trim-primers'
    }
    withName: DORADO_ALIGNER {
        // --mm2-opts takes a single string; the double quotes keep it together
        ext.args = '--mm2-opts "-x map-ont"'
    }
}
```

## GPU

`DORADO_BASECALLER` needs an NVIDIA GPU. The module sets no resources, so the
consuming pipeline passes the GPU through, for example:

```groovy
process {
    withName: DORADO_BASECALLER {
        accelerator      = 1
        containerOptions = '--gpus all'   // Docker; '--nv' for Singularity/Apptainer
    }
}
```

`DORADO_TRIM` and `DORADO_ALIGNER` run on CPU.

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-dorado.git modules/dorado
git -C modules/dorado checkout v1.0.0
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
include { DORADO_DEMUX } from './modules/dorado/demux/main.nf'
include { DORADO_TRIM } from './modules/dorado/trim/main.nf'
include { DORADO_ALIGNER } from './modules/dorado/aligner/main.nf'
```

The basecaller takes the model as its second input:

```groovy
DORADO_BASECALLER(ch_pod5, '/opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0')
```

## Requirements

- Nextflow 26.04.4 or newer.
- For `DORADO_BASECALLER`: an NVIDIA GPU, with a driver that supports CUDA 12.4.

## Tests

`nf-test test`. Every process has a stub test, tagged `stub`, covering wiring
and output names.

`DORADO_TRIM` and `DORADO_ALIGNER` also have tests that run dorado for real on
CPU against `ghcr.io/eit-gbi/nf-mod-dorado:v1.0.0`, using the nf-core sarscov2
nanopore reads (`test_2.fastq.gz`) and genome, and snapshot what comes out.
They need Docker, the image built locally under that tag, and the `nft-bam`
plugin declared in `nf-test.config`, which nf-test fetches on first run. They
share `tests.config` at the repo root; `tests-args.config` adds flags through
`ext.args`. BAM outputs snapshot read-level checksums rather than the file
checksum, because dorado writes its command line and version into an `@PG`
header line.

**CI runs the stub tests only** (`nf-test test --tag stub`). The image is ~11 GB
unpacked, and building it needs more disk than a GitHub-hosted runner has free,
so `.github/workflows/ci.yml` deliberately differs from the org's copy and does
not build it. Run the full suite locally before merging a change to a process
or the Dockerfile:

```bash
docker build -t ghcr.io/eit-gbi/nf-mod-dorado:v1.0.0 .   # tag = conf/module.config
NXF_SYNTAX_PARSER=v1 nf-test test --verbose
```

**`DORADO_BASECALLER` is only stub-tested, locally and in CI.** Basecalling
needs an NVIDIA GPU (the nf-mod-parabricks precedent). A stub test cannot check
the dorado command line: `-stub-run` replaces the whole script block, so the
tool never runs.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
