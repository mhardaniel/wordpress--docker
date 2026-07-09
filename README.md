# wordpress--docker

Local Docker environment for the **real-estate-business** WordPress site (Sage theme).

## Project layout

This repo expects to sit next to two more directories it mounts as volumes:

```
codes/php/
├── wordpress--docker/           # this repo (Docker setup) — git repo
├── real-estate-business/        # WordPress core + wp-content — plain folder, not git
└── real-estate-business-sage/   # Sage theme (wp-content/themes/real-estate-business-sage) — git repo
```

Only `wordpress--docker` and `real-estate-business-sage` are git repos — that's where the custom code lives (infra + theme). `real-estate-business` is WordPress core plus third-party plugins (ACF, Akismet); it's scaffolding, not something to version or review, so it's handed off as a plain folder/DB dump instead of cloned.

Set up all three in the same parent directory before starting.

## Prerequisites

- Docker + Docker Compose
- Git

> Just reviewing code, not running the site? Skip to [For code review only](#for-code-review-only) — none of the setup below is needed.

## First-time setup

1. **Get the three directories side by side** as shown above (clone the two git repos; copy the `real-estate-business` folder from whoever is sharing it).

2. **Create your env file**

   ```bash
   cp .env.example .env
   ```

   Fill in `.env` with your own values (root/DB passwords, etc). Never commit `.env` — it's gitignored.

3. **Start the stack**

   ```bash
   docker compose up -d
   ```

   This builds/starts:
   - `db` — MySQL (creates the `real_estate_business` database on first boot via `mysql/init_db.sql`)
   - `real-estate-business` — PHP-FPM (WordPress), built from `php/Dockerfile`
   - `web` — nginx, serving on **http://localhost:8000**
   - `pma` — phpMyAdmin on **http://localhost:8888**

4. **Import the database** (see below) so the site has content instead of a blank WordPress install.

5. **wp-config.php**: comes along with the `real-estate-business` folder — it's stock WordPress Docker boilerplate with no secrets baked in (DB credentials and auth keys are all read from env vars via `getenv_docker()`). If it's ever missing, the container's entrypoint regenerates it automatically from `.env` on first boot.

## Sharing the project with another user

### For code review only

Push `real-estate-business-sage` (and this repo) to a remote — GitHub/GitLab — and give them access. That's all that's needed; the DB export, media files, and the `real-estate-business` folder below are **not required** just to read/review the theme code.

### For a runnable local environment

If they also need to run the site locally (not just read the code), hand off the `real-estate-business` folder plus a DB export and the media folder:

#### Export the database

```bash
source .env
docker compose exec db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" \
  --single-transaction --set-gtid-purged=OFF --no-tablespaces \
  real_estate_business > exports/real_estate_business_$(date +%Y%m%d).sql
```

`exports/` is gitignored — send the `.sql` file directly (zip/drive/etc), don't commit it. It can contain user emails and password hashes.

#### Import the database

On the receiving end, after `docker compose up -d`:

```bash
source .env
docker compose exec -T db mysql -u root -p"$MYSQL_ROOT_PASSWORD" real_estate_business < exports/real_estate_business_YYYYMMDD.sql
```

#### Media files

Zip and send `real-estate-business/wp-content/uploads/` separately — it isn't part of the DB dump or git.

#### Fix the site URL after import

If the dump came from a different host/port, update the URLs so links and assets resolve locally:

```bash
docker compose exec real-estate-business wp search-replace 'https://old-domain.com' 'http://localhost:8000' --skip-columns=guid
```

## Adding another WordPress site

This stack currently runs one site, but is set up to host more. Templates are provided (commented out) for a second site called `example-site`:

- `docker-compose.yaml` — commented `example-site` service + volume
- `mysql/init_db.sql` — commented `CREATE DATABASE example_site`
- `nginx/config/example-site.conf.example` — copy to `example-site.conf` (only `.conf` files are loaded)

Sites aren't routed by `server_name`, so each additional site needs its own nginx `listen` port and a matching host port under the `web` service's `ports:` (e.g. `8001:81`).

## Useful commands

```bash
# Recreate a single service after a Dockerfile/compose change
docker compose up --force-recreate --no-deps <service>

# Tail logs
docker compose logs -f web real-estate-business

# Stop everything
docker compose down
```
