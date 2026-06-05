# formr dev OpenCPU image — R runtime with the formr R helper package.
# Kept intentionally simple for local dev (no AppArmor sandbox, no baked package
# set). Published publicly to GHCR. NOTE: this permits arbitrary R execution —
# fine for localhost dev, never expose it.
FROM opencpu/base:v2.2.14-2

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran \
    libcairo2-dev libcurl4-openssl-dev libfontconfig1-dev \
    libgsl-dev libjpeg-dev liblapack-dev libmariadb-dev libpng-dev \
    libproj-dev libsodium-dev libssl-dev libudunits2-dev libxml2-dev \
    libglu1-mesa-dev pandoc libbz2-dev liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# formr R package (pulls its dependencies as P3M binaries via opencpu/base's repo)
RUN Rscript -e "install.packages('remotes')" \
    && Rscript -e "remotes::install_github('rubenarslan/formr', dependencies = TRUE)"

COPY clean_up_duplicate_packages.R /clean_up_duplicate_packages.R
RUN Rscript /clean_up_duplicate_packages.R

CMD service cron start && apachectl -DFOREGROUND
