# dorado: ONT basecaller (GPU), trimmer and aligner.
#
# The base is the NVIDIA CUDA runtime image rather than debian-slim: the
# basecaller needs CUDA userspace libraries, and the host GPU is exposed at run
# time with `--gpus all` (Docker) or `--nv` (Singularity/Apptainer). `dorado
# trim` and `dorado aligner` run on CPU and need no GPU.
ARG CUDA_IMAGE=nvidia/cuda:12.4.1-runtime-ubuntu22.04
ARG DORADO_VERSION=0.8.3
# sha256 of dorado-${DORADO_VERSION}-linux-{x64,arm64}.tar.gz. ONT does not
# publish checksums, so these were computed from the CDN downloads.
ARG DORADO_SHA256_AMD64=8b679ed7faa61299af2df591322b2737d61106a53f3175cc2d4efe0a31242ec2
ARG DORADO_SHA256_ARM64=372158718cce6d6b3e09557d5159af3f289f301b33bf8937f37d947407611d35

# Filled in by BuildKit; declared here so they can be used in FROM lines.
ARG BUILDARCH
ARG TARGETARCH

# fetch #######################################################################
#
# One stage per architecture: download, verify and unpack the dorado release.
# They run on the build platform and never execute the binary they fetch, so a
# cross-architecture build does not run anything under emulation here.

FROM --platform=$BUILDPLATFORM ${CUDA_IMAGE} AS fetch-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

FROM fetch-base AS fetch-amd64
ARG DORADO_VERSION
ARG DORADO_SHA256_AMD64
RUN curl -fsSL --retry 3 -o dorado.tar.gz \
        "https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-x64.tar.gz" \
    && echo "${DORADO_SHA256_AMD64}  dorado.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/dorado \
    && tar -xzf dorado.tar.gz -C /opt/dorado --strip-components=1 \
    && rm dorado.tar.gz

FROM fetch-base AS fetch-arm64
ARG DORADO_VERSION
ARG DORADO_SHA256_ARM64
RUN curl -fsSL --retry 3 -o dorado.tar.gz \
        "https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-arm64.tar.gz" \
    && echo "${DORADO_SHA256_ARM64}  dorado.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/dorado \
    && tar -xzf dorado.tar.gz -C /opt/dorado --strip-components=1 \
    && rm dorado.tar.gz

# The dorado that ships in the image, for the target architecture.
FROM fetch-${TARGETARCH} AS dorado

# models ######################################################################
#
# Bake the basecalling models into /opt/models so POD5 runs are offline-safe.
# Models are architecture-independent, so they are downloaded with the build
# platform's own dorado (natively, even in a multi-arch build) and copied into
# every target image.
#
# Pass the simplex model's path as the DORADO_BASECALLER `model` input, e.g.
# /opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0. With --modified-bases, dorado
# 0.8.3 looks for the modified-base model in --models-directory (default: the
# working directory), not next to the simplex model, and otherwise downloads
# it. Offline runs therefore need `--models-directory /opt/models` in ext.args.

FROM fetch-${BUILDARCH} AS models
# libnuma is the one library dorado links that neither its tarball nor the
# CUDA base ships (the linux-arm64 build fails to start without it).
RUN apt-get update \
    && apt-get install -y --no-install-recommends libnuma1 \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/models \
    && for model in \
        dna_r10.4.1_e8.2_400bps_sup@v5.0.0 \
        dna_r10.4.1_e8.2_400bps_sup@v5.0.0_5mCG_5hmCG@v2.0.1 \
        dna_r10.4.1_e8.2_400bps_sup@v5.0.0_6mA@v2 \
        dna_r10.4.1_e8.2_400bps_sup@v5.0.0_4mC_5mC@v2 \
        dna_r10.4.1_e8.2_400bps_hac@v5.0.0 \
        dna_r10.4.1_e8.2_400bps_hac@v5.0.0_6mA@v2 \
        dna_r10.4.1_e8.2_400bps_hac@v5.0.0_4mC_5mC@v2 \
    ; do \
        /opt/dorado/bin/dorado download --model "${model}" --directory /opt/models || exit 1; \
    done

# runtime #####################################################################

FROM ${CUDA_IMAGE} AS runtime

ARG CUDA_IMAGE
ARG DORADO_VERSION

LABEL org.opencontainers.image.title="dorado" \
    org.opencontainers.image.description="dorado ${DORADO_VERSION} with baked-in R10.4.1 models on ${CUDA_IMAGE}" \
    org.opencontainers.image.version="${DORADO_VERSION}" \
    org.opencontainers.image.source="https://github.com/nanoporetech/dorado" \
    org.opencontainers.image.licenses="LicenseRef-ONT-Public-License-1.0"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/dorado/bin:${PATH} \
    LC_ALL=C.UTF-8

# No `apt-get upgrade` here, unlike the debian-based modules: the CUDA
# userspace libraries in this base come from NVIDIA's apt repository, and an
# upgrade could move them away from the versions the base image was built and
# tested with. ca-certificates stays so dorado can still fetch a model by name
# (e.g. `sup`) when one is not baked in.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libnuma1 \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=dorado /opt/dorado /opt/dorado
COPY --from=models /opt/models /opt/models

# Kept for anything that calls dorado by the path the previous image used.
RUN ln -s /opt/dorado/bin/dorado /usr/local/bin/dorado

# No ENTRYPOINT: Nextflow invokes the container as `/bin/bash -c ...`, and an
# ENTRYPOINT of ["dorado"] would turn that into `dorado /bin/bash`. The CUDA base
# sets /opt/nvidia/nvidia_entrypoint.sh, which only prints a licence banner and
# a driver check before exec'ing the command, so it is cleared rather than
# inherited.
ENTRYPOINT []
CMD ["dorado", "--version"]
