# syntax=docker/dockerfile:1

ARG PHP_VERSION=8.3

# ---------------------------------------------------------
# Frontend builder
# ---------------------------------------------------------
FROM node:22-bookworm AS frontend

ARG CACHET_REF=3.x

WORKDIR /build

RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${CACHET_REF}" \
  https://github.com/cachethq/cachet.git .

RUN npm ci
RUN npm run build


# ---------------------------------------------------------
# PHP dependencies builder
# ---------------------------------------------------------
FROM composer:2 AS composer

ARG CACHET_REF=3.x

WORKDIR /build

RUN apk add --no-cache git

RUN git clone --depth 1 --branch "${CACHET_REF}" \
  https://github.com/cachethq/cachet.git .

RUN composer install \
  --no-dev \
  --no-interaction \
  --prefer-dist \
  --optimize-autoloader \
  --no-progress


# ---------------------------------------------------------
# Runtime
# ---------------------------------------------------------
FROM php:${PHP_VERSION}-apache

ARG CACHET_REF=3.x

LABEL org.opencontainers.image.title="Cachet"
LABEL org.opencontainers.image.description="Cachet 3.x status page"
LABEL org.opencontainers.image.source="https://github.com/cachethq/cachet"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"

WORKDIR /var/www/html

# System dependencies + PHP extensions
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git \
  curl \
  unzip \
  libpq-dev \
  libicu-dev \
  libzip-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libfreetype6-dev \
  libonig-dev \
  && docker-php-ext-configure gd \
  --with-freetype \
  --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" \
  bcmath \
  exif \
  gd \
  intl \
  mbstring \
  opcache \
  pcntl \
  pdo \
  pdo_pgsql \
  zip \
  && a2enmod rewrite headers \
  && rm -rf /var/lib/apt/lists/*

# Apache must serve Laravel's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri \
  -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
  /etc/apache2/sites-available/*.conf \
  /etc/apache2/apache2.conf \
  /etc/apache2/conf-available/*.conf

# Copy Cachet source
RUN git clone --depth 1 --branch "${CACHET_REF}" \
  https://github.com/cachethq/cachet.git .

# Copy PHP dependencies
COPY --from=composer /build/vendor ./vendor

# Copy compiled frontend
COPY --from=frontend /build/public/build ./public/build

# Ensure Laravel storage/cache directories exist
RUN mkdir -p \
  storage/framework/cache \
  storage/framework/sessions \
  storage/framework/views \
  storage/logs \
  bootstrap/cache \
  && chown -R www-data:www-data \
  storage \
  bootstrap/cache \
  && chmod -R ug+rwx \
  storage \
  bootstrap/cache

# PHP production settings
RUN { \
  echo 'opcache.enable=1'; \
  echo 'opcache.validate_timestamps=0'; \
  echo 'opcache.memory_consumption=192'; \
  echo 'opcache.max_accelerated_files=20000'; \
  echo 'memory_limit=512M'; \
  echo 'upload_max_filesize=32M'; \
  echo 'post_max_size=32M'; \
  } > /usr/local/etc/php/conf.d/cachet.ini

COPY docker/entrypoint.sh /usr/local/bin/cachet-entrypoint

RUN chmod +x /usr/local/bin/cachet-entrypoint

EXPOSE 80

ENTRYPOINT ["cachet-entrypoint"]

CMD ["apache2-foreground"]