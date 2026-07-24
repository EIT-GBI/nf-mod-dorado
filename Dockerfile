# Dorado — ONT basecaller (GPU). Needs CUDA at runtime + host GPUs (--nv).
# TODO: pin the exact Dorado version before building the released image.
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ARG DORADO_VERSION=0.8.3
ARG DORADO_SHA256=8b679ed7faa61299af2df591322b2737d61106a53f3175cc2d4efe0a31242ec2
ARG DORADO_URL="https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-x64.tar.gz"

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8

# Basecalling models baked into the image so POD5 runs are offline-safe. These
# match the pipeline defaults (basecall.model / basecall.modified_bases); the
# mod model is the latest 5mCG_5hmCG variant Dorado auto-selects for the sup
# v5.0.0 simplex model. Override at build time if you change those params.
ARG DORADO_MODEL=dna_r10.4.1_e8.2_400bps_sup@v5.0.0
ARG DORADO_MOD_MODEL=dna_r10.4.1_e8.2_400bps_sup@v5.0.0_5mCG_5hmCG@v2.0.1
ARG DORADO_MOD_MODEL_6MA=dna_r10.4.1_e8.2_400bps_sup@v5.0.0_6mA@v3

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL --retry 3 -o /tmp/dorado.tar.gz "${DORADO_URL}" \
    && echo "${DORADO_SHA256}  /tmp/dorado.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/dorado.tar.gz -C /opt \
    && rm /tmp/dorado.tar.gz \
    && ln -s /opt/dorado-${DORADO_VERSION}-linux-x64/bin/dorado /usr/local/bin/dorado \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Pre-download the main basecalling models into /opt/models. Both land as
# sibling dirs, so pointing basecall.model at the simplex model's PATH lets
# Dorado find the adjacent mod model when --modified-bases is set — no network
# access at run time. A bare model NAME would instead re-download to the CWD.
#   params.basecall.model = '/opt/models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0'
RUN mkdir -p /opt/models \
    && dorado download --model "${DORADO_MODEL}" --directory /opt/models \
    && dorado download --model "${DORADO_MOD_MODEL}" --directory /opt/models \
    && dorado download --model "${DORADO_MOD_MODEL_6MA}" --directory /opt/models

LABEL org.opencontainers.image.title="dorado" \
      org.opencontainers.image.description="Oxford Nanopore Dorado basecaller" \
      org.opencontainers.image.version="${DORADO_VERSION}" \
      org.opencontainers.image.source="https://github.com/nanoporetech/dorado" \
      org.opencontainers.image.licenses="ONT-Public-License"
