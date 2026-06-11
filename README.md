# formr dockerized development environment

A minimal local environment for **developing and trying [formr.org](https://github.com/rubenarslan/formr.org)**.
It runs the app, MariaDB, OpenCPU and the two queue daemons — nothing else (no
TLS, no WAF, no monitoring, no backups). **Not for production:** OpenCPU permits
arbitrary R code execution, the DB and HTTP are unencrypted.

The formr source is **bind-mounted** from `./formr_app/formr`, so you edit it on
your host (with your IDE + Xdebug) and changes are live in the container.

## Requirements
- [Docker + Docker Compose v2](https://docs.docker.com/compose/install/)

## Quick start
```bash
./setup.sh     # creates .env, clones formr.org into ./formr_app/formr, seeds the DB schema (destructive)
# (optionally edit .env — e.g. FORMR_TAG, passwords)
./build.sh     # builds images, starts the stack, configures settings.php, creates the superadmin
```
Then open **http://localhost** (admin login at `http://localhost/admin/account/login`,
using `FORMR_EMAIL` / `FORMR_PASSWORD` from `.env`). OpenCPU is at `http://localhost:8080/ocpu/`.

The first `build.sh` takes a few minutes: the OpenCPU image compiles the formr
R package and its missing CRAN dependencies from source (the heavy ones ship
with `opencpu/base`), and the app container's entrypoint runs `composer install`
and builds the frontend bundles with `npm` (formr v1.0.0+ no longer commits
them).

## Using the prebuilt public images (skip the local image build)
The three environment images are published to GHCR (amd64 only — on Apple
Silicon skip this and build locally, which is the default). To pull instead of
build:
```bash
echo "FORMR_REGISTRY=ghcr.io/rubenarslan" >> .env   # already the default
docker compose pull        # formr-dev-app / -daemon / -opencpu
./build.sh                 # `docker compose build` becomes a fast no-op
```

## What's inside
| service | image | role |
| --- | --- | --- |
| `formr_app` | `formr-dev-app` (PHP 8.2 + Apache + Xdebug + Node) | the app; bind-mounts `./formr_app/formr` |
| `formr_db` | `mariadb:noble` | database; loads `sql/schema.sql` on first init |
| `opencpu` | `formr-dev-opencpu` | R runtime with the formr R package |
| `formrmailqueue` / `formrsessionqueue` | `formr-dev-daemon` (PHP 8.2 CLI) | email + run/session workers |

## Common tasks
```bash
docker compose logs -f formr_app          # watch logs
docker compose exec formr_app bash        # shell into the app
docker compose exec formr_app composer install   # after pulling new formr code
docker compose exec formr_app npm run webpack:build && docker compose exec formr_app npm run build  # rebuild assets
./reset_2fa_for_user.sh                    # clear a user's 2FA
```

**Xdebug** runs in trigger mode (step-debug to `host.docker.internal:9003`, idekey
`VSCODE`). It only activates when an `XDEBUG_TRIGGER` cookie/GET param is present,
so normal requests aren't slowed.

To switch the formr version: edit `FORMR_TAG` in `.env`, re-clone
`./formr_app/formr`, and re-run `./setup.sh && ./build.sh`.
