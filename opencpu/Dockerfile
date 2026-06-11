# formr dev OpenCPU image — R runtime with the formr R helper package.
# Kept intentionally simple for local dev (no AppArmor sandbox, no baked package
# set). Published publicly to GHCR. NOTE: this permits arbitrary R execution —
# fine for localhost dev, never expose it.
FROM opencpu/base:v2.2.14-2

# Headers for compiling CRAN packages from source (plain CRAN serves no Linux
# binaries). Beyond formr's own tree (libuv -> fs, libsecret -> keyring,
# libicu -> stringi), keep common ones so users can install more packages at
# runtime via OpenCPU.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran pkg-config \
    libcairo2-dev libcurl4-openssl-dev libfontconfig1-dev libfreetype6-dev \
    libfribidi-dev libgit2-dev libgsl-dev libharfbuzz-dev libicu-dev \
    libjpeg-dev liblapack-dev libmariadb-dev libpng-dev \
    libproj-dev libsecret-1-dev libsodium-dev libssl-dev libtiff-dev \
    libudunits2-dev libuv1-dev libxml2-dev \
    libglu1-mesa-dev pandoc libbz2-dev liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# formr R package + its dependencies, compiled from source (Ncpus parallelizes
# across packages; expect ~30-60 min). No binary repo is baked into the image.
RUN Rscript -e "options(Ncpus = parallel::detectCores()); install.packages('remotes')" \
    && Rscript -e "options(Ncpus = parallel::detectCores()); remotes::install_github('rubenarslan/formr', dependencies = TRUE)"

COPY clean_up_duplicate_packages.R /clean_up_duplicate_packages.R
RUN Rscript /clean_up_duplicate_packages.R

CMD service cron start && apachectl -DFOREGROUND
