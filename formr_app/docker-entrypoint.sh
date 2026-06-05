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

# composer/npm run as root here; hand the generated dirs back to the host owner
# of the /formr bind-mount so they stay editable/removable on the host without
# sudo (www-data still reads them via 0644). Called only right after an install.
HOST_UID=$(stat -c %u /formr 2>/dev/null || echo 0)
HOST_GID=$(stat -c %g /formr 2>/dev/null || echo 0)
chown_to_host() { [ "$HOST_UID" != "0" ] && chown -R "$HOST_UID:$HOST_GID" "$@" 2>/dev/null || true; }

# Seed config/ from config-dist/ on first run (build.sh then fills settings.php).
if [ -d /formr/config-dist ] && [ ! -d /formr/config ]; then
    cp -r /formr/config-dist /formr/config
    echo "> Seeded config/ from config-dist/"
fi

# PHP dependencies
if [ -f /formr/composer.json ] && [ ! -f /formr/vendor/autoload.php ]; then
    echo "> Installing PHP dependencies (composer)..."
    composer install --no-interaction
    chown_to_host /formr/vendor
fi

# Frontend bundles. webpack:build runs FIRST because webpack.config.js sets
# output.clean=true (wipes the build dir); the legacy `npm run build` (css/js/
# fonts) lands on top. webpack writes admin.bundle.js into build/js/, so its
# presence is the "already built" marker.
if [ -f /formr/package.json ] && [ ! -f /formr/webroot/assets/build/js/admin.bundle.js ]; then
    echo "> Building frontend assets (npm ci + webpack + build)..."
    npm ci --no-audit --no-fund \
        && npm run webpack:build \
        && npm run build
    chown_to_host /formr/node_modules /formr/webroot/assets/build
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
