# Cachet Docker

Docker image and deployment setup for [Cachet](https://github.com/cachethq/cachet) 3.x.

This repository provides a containerized Cachet 3.x build that can be published to **GitHub Container Registry (GHCR)** and deployed easily with **Coolify**.

> **Note:** Cachet 3.x is currently under development and may not be considered production-ready by the Cachet project.

## Features

* Cachet 3.x
* PHP 8.3
* PostgreSQL support
* Apache + PHP
* Laravel migrations run automatically on startup
* Laravel production optimizations
* Frontend assets built during the Docker build
* GitHub Actions CI/CD
* Automatic publishing to GitHub Container Registry
* Ready for deployment with Coolify
* No secrets stored in the repository

## Docker Image

The image is published to GitHub Container Registry:

```text
ghcr.io/YOUR_USERNAME/cachet-docker:3.x
```

Replace `YOUR_USERNAME` with your GitHub username.

## Running with Docker

### PostgreSQL

Cachet requires a database. The recommended setup is PostgreSQL.

Example:

```bash
docker run -d \
  --name cachet \
  -p 8080:80 \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e APP_KEY=base64:YOUR_APP_KEY \
  -e APP_URL=http://localhost:8080 \
  -e DB_CONNECTION=pgsql \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_DATABASE=cachet \
  -e DB_USERNAME=cachet \
  -e DB_PASSWORD=YOUR_PASSWORD \
  ghcr.io/YOUR_USERNAME/cachet-docker:3.x
```

For production deployments, use Docker Compose or Coolify rather than manually passing secrets on the command line.

## Environment Variables

The container uses standard Laravel and Cachet environment variables.

### Application

| Variable       | Description               | Example                      |
| -------------- | ------------------------- | ---------------------------- |
| `APP_NAME`     | Application name          | `Cachet`                     |
| `APP_ENV`      | Application environment   | `production`                 |
| `APP_DEBUG`    | Enable Laravel debug mode | `false`                      |
| `APP_KEY`      | Laravel encryption key    | `base64:...`                 |
| `APP_URL`      | Public Cachet URL         | `https://status.example.com` |
| `APP_TIMEZONE` | Application timezone      | `UTC`                        |

### Database

| Variable        | Description         | Example     |
| --------------- | ------------------- | ----------- |
| `DB_CONNECTION` | Database driver     | `pgsql`     |
| `DB_HOST`       | PostgreSQL hostname | `cachet-db` |
| `DB_PORT`       | PostgreSQL port     | `5432`      |
| `DB_DATABASE`   | Database name       | `cachet`    |
| `DB_USERNAME`   | Database user       | `cachet`    |
| `DB_PASSWORD`   | Database password   | `********`  |

### Cache / Queue / Sessions

| Variable           | Description           | Example    |
| ------------------ | --------------------- | ---------- |
| `CACHE_STORE`      | Laravel cache backend | `database` |
| `SESSION_DRIVER`   | Session backend       | `database` |
| `QUEUE_CONNECTION` | Queue backend         | `database` |
| `FILESYSTEM_DISK`  | Filesystem disk       | `local`    |

### Cachet

| Variable                 | Description                          | Example |
| ------------------------ | ------------------------------------ | ------- |
| `CACHET_BEACON`          | Enable Cachet beacon                 | `false` |
| `CACHET_EMOJI`           | Enable emoji support                 | `false` |
| `CACHET_AUTO_TWITTER`    | Enable automatic Twitter integration | `false` |
| `CACHET_PATH`            | Cachet application path              | `/`     |
| `CACHET_TRUSTED_PROXIES` | Trusted proxy configuration          | `*`     |

## Docker Compose

A typical deployment consists of two services:

```text
Cachet
  │
  └── PostgreSQL
```

Cachet connects to PostgreSQL using:

```text
DB_HOST=cachet-db
DB_PORT=5432
```

The PostgreSQL data should be stored in a persistent volume.

## Coolify

This image is designed to work with Coolify.

Coolify can pull the image directly from GHCR:

```yaml
services:
  cachet:
    image: ghcr.io/YOUR_USERNAME/cachet-docker:3.x
```

The recommended Coolify setup uses Coolify's generated environment variables for:

* Database username
* Database password
* Application key
* Public service URL

For example:

```text
${SERVICE_USER_POSTGRES}
${SERVICE_PASSWORD_POSTGRES}
${SERVICE_REALBASE64_32_CACHET}
${SERVICE_URL_CACHET_80}
```

No passwords or application keys should be committed to this repository.

## GitHub Container Registry

The Docker image is built and published automatically using GitHub Actions.

The workflow:

1. Checks out the repository.
2. Logs in to GHCR using `GITHUB_TOKEN`.
3. Builds the Cachet Docker image.
4. Tags the image.
5. Pushes the image to GHCR.

The workflow requires:

```yaml
permissions:
  contents: read
  packages: write
```

## Building Locally

Build the image:

```bash
docker build \
  --build-arg CACHET_REF=3.x \
  -t cachet:3.x .
```

Run it:

```bash
docker run --rm \
  -p 8080:80 \
  cachet:3.x
```

For a functional installation, provide the required Laravel and PostgreSQL environment variables.

## Cachet Version

The Docker build uses the Cachet `3.x` branch by default:

```text
CACHET_REF=3.x
```

For reproducible production builds, it is recommended to pin the build to a specific Cachet commit or release once an appropriate stable version is available.

## Persistent Data

The following directory should be persisted:

```text
/var/www/html/storage
```

PostgreSQL data should also be persisted:

```text
/var/lib/postgresql/data
```

Do not store application secrets inside the Docker image.

## Security

This repository intentionally does not contain:

* Database passwords
* Laravel application keys
* API tokens
* SMTP passwords
* Cloud credentials

Secrets should be supplied through the deployment platform, such as Coolify.

If the GHCR package is public, anyone can pull the Docker image. Make sure no secrets are ever copied into the image during the build.

## Updating Cachet

To update the Cachet version, change the build argument:

```yaml
build-args: |
  CACHET_REF=3.x
```

Or pin it to a specific Git reference:

```yaml
build-args: |
  CACHET_REF=<commit-or-tag>
```

Then push the change to GitHub. GitHub Actions will build and publish the new image.

## License

This repository contains Docker and deployment configuration for Cachet.

Cachet itself is licensed under the license specified by the upstream Cachet project:

https://github.com/cachethq/cachet
