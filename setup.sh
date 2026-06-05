#!/bin/bash
# One-time (destructive) setup for the formr dev environment:
#  - creates .env from .env.example
#  - clones formr.org host-side into ./formr_app/formr (so files are owned by you)
#  - seeds the DB schema for MariaDB's first-run auto-init
#  - WIPES any existing local DB data
# After this, run ./build.sh.
set -e
cd "$(dirname "$0")"

if [ ! -f .env ]; then
    cp .env.example .env
    echo "> Created .env from .env.example"
fi
set -a; . ./.env; set +a

echo ""
echo "This is DESTRUCTIVE: it stops the stack and wipes ./mysql/data (your local"
echo "formr database). Your ./formr_app/formr checkout is kept if already present."
echo "Press any key to continue, or Ctrl+C to abort."
read -n 1 -s -r

docker compose down 2>/dev/null || true
rm -rf mysql/data/* mysql/dbinitial/*
mkdir -p mysql/data mysql/dbinitial formr_app/formr

# Clone formr.org host-side (correct ownership) unless a checkout is already there.
if [ ! -f formr_app/formr/composer.json ]; then
    echo "> Cloning formr.org@${FORMR_TAG} into ./formr_app/formr ..."
    rm -rf formr_app/formr
    git clone -b "${FORMR_TAG}" https://github.com/rubenarslan/formr.org.git formr_app/formr
else
    echo "> Keeping existing ./formr_app/formr checkout"
fi
[ -d formr_app/formr/config ] || cp -r formr_app/formr/config-dist formr_app/formr/config

# Seed the schema so MariaDB loads it during its first init (before it accepts
# connections — no race). schema.sql creates/uses db 'formr', matching
# MARIADB_DATABASE=formr.
cp formr_app/formr/sql/schema.sql mysql/dbinitial/schema.sql
echo "> Seeded mysql/dbinitial/schema.sql"

echo ""
echo "Setup complete. Next:"
echo "  1. (optional) edit .env"
echo "  2. ./build.sh"
