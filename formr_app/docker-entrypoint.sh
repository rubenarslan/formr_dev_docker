#!/bin/bash
# formr dev entrypoint. The formr source is bind-mounted at /formr (cloned
# host-side by setup.sh). On first start we install PHP + JS deps and build the
# frontend bundles (formr v1.0.0+ no longer ships them), set up cron, then run
# apache. Steps are idempotent (guarded by markers) so restarts are fast.
#
# We deliberately do NOT exit on step failure — apache still comes up so the
# container stays inspectable; check the logs if composer/npm reported errors.

if [ ! -f /formr/composer.json ]; then
    echo "E: /formr has no formr source. Clone formr.org into ./formr_app/formr" >&2
    echo "E: (run ./setup.sh), then start again." >&2
fi

cd /formr 2>/dev/null || true

# Seed config/ from config-dist/ on first run (build.sh then fills settings.php).
if [ -d /formr/config-dist ] && [ ! -d /formr/config ]; then
    cp -r /formr/config-dist /formr/config
    echo "> Seeded config/ from config-dist/"
fi

# PHP dependencies
if [ -f /formr/composer.json ] && [ ! -f /formr/vendor/autoload.php ]; then
    echo "> Installing PHP dependencies (composer)..."
    composer install --no-interaction
fi

# Frontend bundles. webpack:build runs FIRST because webpack.config.js sets
# output.clean=true (wipes the build dir); the legacy `npm run build` (css/js/
# fonts) lands on top. admin.bundle.js is a webpack output, so its presence is
# the "already built" marker.
if [ -f /formr/package.json ] && [ ! -f /formr/webroot/assets/build/admin.bundle.js ]; then
    echo "> Building frontend assets (npm ci + webpack + build)..."
    npm ci --no-audit --no-fund \
        && npm run webpack:build \
        && npm run build
fi

mkdir -p /formr/tmp
chown -R www-data:www-data /formr/tmp 2>/dev/null || true

# Cron: formr_crontab lives in the cloned repo, so register it here (NOT at
# image build time, where it doesn't exist yet — that was the build failure).
if [ -f /formr/config/formr_crontab ]; then
    crontab /formr/config/formr_crontab && echo "> Registered formr crontab"
fi

# Apache logs -> container stdout/stderr
ln -sf /proc/self/fd/1 /var/log/apache2/access.log
ln -sf /proc/self/fd/2 /var/log/apache2/error.log

service cron start
exec apache2-foreground
