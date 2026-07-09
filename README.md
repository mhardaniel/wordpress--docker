# wordpress--docker

Local Docker environment for the **real-estate-business** WordPress site (Sage theme).

## Project layout

This repo expects to sit next to the two code repos it mounts as volumes:

```
codes/php/
├── wordpress--docker/           # this repo (Docker setup)
├── real-estate-business/        # WordPress core + wp-content
└── real-estate-business-sage/   # Sage theme (wp-content/themes/real-estate-business-sage)
```

Clone all three into the same parent directory before starting.

## Prerequisites

- Docker + Docker Compose
- Git

## First-time setup

1. **Clone the repos side by side** as shown above.

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

5. **wp-config.php**: `real-estate-business/wp-config.php` is not tracked in git and isn't included in the DB dump. Get a copy from whoever is sharing the project with you (it reads DB credentials from the container's env vars via `getenv_docker`, so it should work as-is once `.env` is set).

## Sharing the project with another user

Hand off three things: the three repos (git), a DB export, and the `wp-content/uploads` media folder (also not in git).

### Export the database

```bash
source .env
docker compose exec db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" \
  --single-transaction --set-gtid-purged=OFF --no-tablespaces \
  real_estate_business > exports/real_estate_business_$(date +%Y%m%d).sql
```

`exports/` is gitignored — send the `.sql` file directly (zip/drive/etc), don't commit it. It can contain user emails and password hashes.

### Import the database

On the receiving end, after `docker compose up -d`:

```bash
source .env
docker compose exec -T db mysql -u root -p"$MYSQL_ROOT_PASSWORD" real_estate_business < exports/real_estate_business_YYYYMMDD.sql
```

### Media files

Zip and send `real-estate-business/wp-content/uploads/` separately — it isn't part of the DB dump or git.

### Fix the site URL after import

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
