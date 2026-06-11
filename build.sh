#!/bin/bash
# Build the dev images, bring up the stack, configure settings.php for local
# dev, and create the superadmin. Run ./setup.sh first. Safe to re-run.
#
# The DB schema is loaded automatically by MariaDB on first init (setup.sh seeds
# mysql/dbinitial/schema.sql), so there is no manual schema-load step or race.
set -e
cd "$(dirname "$0")"
[ -f .env ] || { echo "E: run ./setup.sh first"; exit 1; }
set -a; . ./.env; set +a
[ -f formr_app/formr/composer.json ] || { echo "E: ./formr_app/formr is empty — run ./setup.sh"; exit 1; }

echo "> Building images... (use 'docker compose pull' instead once the public images are published)"
docker compose build

echo "> Starting db, opencpu, formr_app..."
docker compose up -d formr_db opencpu formr_app

echo "> Waiting for formr_app first-run setup (composer + npm asset build — minutes on first run)..."
until docker compose exec -T formr_app test -f /formr/vendor/autoload.php 2>/dev/null; do sleep 3; done
echo "  composer install done"
until docker compose exec -T formr_app test -f /formr/webroot/assets/build/js/admin.bundle.js 2>/dev/null; do sleep 5; done
echo "  frontend assets built"

# sed -i is not portable: GNU sed takes -i without an argument, BSD/macOS sed
# requires a suffix ('' for none).
if sed --version >/dev/null 2>&1; then sedi() { sed -i "$@"; }; else sedi() { sed -i '' "$@"; }; fi

cfg="formr_app/formr/config/settings.php"
if grep -q "'host' => 'localhost'," "$cfg" 2>/dev/null; then
    echo "> Configuring $cfg for local dev..."
    # DB sub-array (creds read from the container env passed in docker-compose.yml)
    sedi "s#'host' => 'localhost',#'host' => 'formr_db',#"                 "$cfg"
    sedi "s#'login' => 'user',#'login' => getenv('MARIADB_USER'),#"        "$cfg"
    sedi "s#'password' => 'password',#'password' => getenv('MARIADB_PASSWORD'),#" "$cfg"
    sedi "s#'database' => 'database',#'database' => getenv('MARIADB_DATABASE'),#" "$cfg"
    # OpenCPU URL (two occurrences -> global)
    sedi "s#'public_url' => 'https://public.opencpu.org'#'public_url' => 'http://${OPENCPU_DOMAIN}'#g" "$cfg"
    # Top-level $settings[...] lines (\$ so bash doesn't expand it)
    sedi "s#^\$settings\['protocol'\].*#\$settings['protocol'] = 'http://';#"                     "$cfg"
    sedi "s#^\$settings\['use_study_subdomains'\].*#\$settings['use_study_subdomains'] = false;#" "$cfg"
    sedi "s#^\$settings\['admin_domain'\].*#\$settings['admin_domain'] = '${FORMR_DOMAIN}';#"     "$cfg"
    sedi "s#^\$settings\['study_domain'\].*#\$settings['study_domain'] = '${FORMR_DOMAIN}';#"      "$cfg"
    sedi "s#^\$settings\['api_domain'\].*#\$settings['api_domain'] = '${FORMR_DOMAIN}';#"          "$cfg"
    docker compose restart formr_app
else
    echo "> $cfg already configured — skipping"
fi

echo "> Starting daemons..."
docker compose up -d

echo "> Creating superadmin ${FORMR_EMAIL}..."
docker compose exec -T formr_app php bin/initialize.php || true
docker compose exec -T formr_app php bin/add_user.php -e "${FORMR_EMAIL}" -p "${FORMR_PASSWORD}" -l 100 || true

echo ""
echo "Done."
echo "  formr   -> http://localhost   (admin login: http://localhost/admin/account/login)"
echo "  opencpu -> http://localhost:8080/ocpu/"
echo "  superadmin: ${FORMR_EMAIL} / (FORMR_PASSWORD from .env)"
