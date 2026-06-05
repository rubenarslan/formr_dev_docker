# formr dev environment image — PHP 8.2 + Apache + Xdebug + Composer + Node 20.
# Contains NO formr source: the code is bind-mounted from ./formr_app/formr
# (cloned host-side by setup.sh). The entrypoint runs composer/npm/cron at
# container start on the bind-mounted code. Published publicly to GHCR so a
# `docker compose up` pulls this instead of building. See README.
FROM php:8.2-apache-trixie

# System libs + PHP extensions. gmp/bcmath/intl are required by formr v1.0.0+.
RUN apt-get update \
    && apt-get install -y ca-certificates \
    && apt-get upgrade -y \
    && apt-get install -y pandoc libzip-dev libxml2-dev libpng-dev libonig-dev \
       libsodium-dev libcurl4-openssl-dev git unzip libapache2-mod-xsendfile cron \
       libgmp-dev libicu-dev \
    && update-ca-certificates \
    && docker-php-ext-install zip xml gd intl mbstring curl pdo pdo_mysql gmp bcmath \
    && docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite headers ssl xsendfile proxy proxy_http proxy_balancer lbmethod_byrequests

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Node 20 — formr.org v1.0.0+ stopped committing webroot/assets/build bundles, so
# the entrypoint builds them with `npm run webpack:build && npm run build`.
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Xdebug (trigger-mode; configured by xdebug.ini, bind-mounted by compose)
RUN pecl install xdebug && docker-php-ext-enable xdebug

WORKDIR /formr

# Entrypoint clones-deps/builds-assets/sets-up-cron then starts apache.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
