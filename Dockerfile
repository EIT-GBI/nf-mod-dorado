# Dorado — ONT basecaller (GPU). Needs CUDA at runtime + host GPUs (--nv).
# Built for linux/amd64 only; runs on the x86 GPU cluster nodes.
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ARG DORADO_VERSION=0.8.3
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://cdn.oxfordnanoportal.com/software/analysis/dorado-${DORADO_VERSION}-linux-x64.tar.gz" \
        | tar -xz -C /opt \
    && ln -s /opt/dorado-${DORADO_VERSION}-linux-x64/bin/dorado /usr/local/bin/dorado \
    && rm -rf /var/lib/apt/lists/*

# Bake the basecalling models into /opt/models so POD5 runs are offline-safe.
# Point params.basecall.model at the simplex model's path; the sibling mod
# models are picked up automatically when --modified-bases is set.
RUN mkdir -p /opt/models \
    && dorado download --model dna_r10.4.1_e8.2_400bps_sup@v5.0.0 --directory /opt/models \
    && dorado download --model dna_r10.4.1_e8.2_400bps_sup@v5.0.0_5mCG_5hmCG@v2.0.1 --directory /opt/models \
    && dorado download --model dna_r10.4.1_e8.2_400bps_sup@v5.0.0_6mA@v2 --directory /opt/models
