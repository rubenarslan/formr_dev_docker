# formr dev daemon image — PHP 8.2 CLI for the mail/session queue workers.
# No formr code baked: the workers run on the shared ./formr_app/formr bind-mount
# (vendor/ installed by formr_app's entrypoint). Published publicly to GHCR.
FROM php:8.2-cli-trixie

RUN apt-get update \
    && apt-get install -y ca-certificates && apt-get upgrade -y \
    && apt-get install -y pandoc libzip-dev libxml2-dev libpng-dev libonig-dev \
       libsodium-dev libcurl4-openssl-dev git cron libgmp-dev libicu-dev \
    && update-ca-certificates \
    && docker-php-ext-install zip xml gd intl mbstring curl pdo pdo_mysql gmp bcmath \
    && docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /formr
