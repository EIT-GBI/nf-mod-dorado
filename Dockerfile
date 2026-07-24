FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ARG DORADO_VERSION=0.8.3
ARG DORADO_MODEL=dna_r10.4.1_e8.2_400bps_sup@v5.0.0
ARG DORADO_MOD_MODEL=dna_r10.4.1_e8.2_400bps_sup@v5.0.0_5mCG_5hmCG@v2.0.1
ARG DORADO_MOD_MODEL_6MA=dna_r10.4.1_e8.2_400bps_sup@v5.0.0_6mA@v3

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-x64.tar.gz" \
        | tar -xz -C /opt \
    && ln -s /opt/dorado-${DORADO_VERSION}-linux-x64/bin/dorado /usr/local/bin/dorado \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Pre-download the main basecalling models into /opt/models. Both land as
# sibling dirs, so pointing basecall.model at the simplex model's PATH lets
RUN dorado download --model "${DORADO_MODEL}" --directory /opt/models \
    && dorado download --model "${DORADO_MOD_MODEL}" --directory /opt/models \
    && dorado download --model "${DORADO_MOD_MODEL_6MA}" --directory /opt/models
    
LABEL org.opencontainers.image.title="dorado" \
      org.opencontainers.image.description="Oxford Nanopore Dorado basecaller" \
      org.opencontainers.image.licenses="ONT-Public-License"

