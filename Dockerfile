FROM mambaorg/micromamba:1.5.8

USER root

# TODO: pin the version, e.g. __NAME__=1.21
# (remove this TODO line once pinned — the CI build job is gated on its absence)
RUN micromamba install -y -n base -c bioconda -c conda-forge \
        __NAME__ \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:$PATH

CMD ["__NAME__"]
