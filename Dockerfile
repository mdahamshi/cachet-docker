# syntax=docker/dockerfile:1

FROM php:8.3-apache AS base

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# System packages + PHP extensions required by Cachet/Laravel dependencies.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git \
  unzip \
  libicu-dev \
  libpq-dev \
  libzip-dev \
  libxml2-dev \
  libonig-dev \
  && docker-php-ext-install -j"$(nproc)" \
  bcmath \
  intl \
  mbstring \
  pdo \
  pdo_mysql \
  pdo_pgsql \
  simplexml \
  zip \
  && a2enmod rewrite \
  && rm -rf /var/lib/apt/lists/*

# Make Apache serve Laravel's public directory.
RUN sed -ri \
  -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" \
  /etc/apache2/sites-available/*.conf \
  /etc/apache2/apache2.conf \
  /etc/apache2/conf-available/*.conf

WORKDIR /var/www/html


# ---------------------------------------------------------
# Composer
# ---------------------------------------------------------

FROM base AS build

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG CACHET_REF=3.x

# Cachet source
RUN git clone \
  --branch "${CACHET_REF}" \
  --depth 1 \
  https://github.com/cachethq/cachet.git \
  /var/www/html

WORKDIR /var/www/html

# Official Cachet installation step:
# composer install --no-dev -o
RUN composer install \
  --no-dev \
  --optimize-autoloader \
  --no-interaction \
  --prefer-dist

# Official Cachet v3 installation step:
# composer update cachethq/core
RUN composer update cachethq/core \
  --no-dev \
  --optimize-autoloader \
  --no-interaction \
  --prefer-dist

# Cachet's official installation requires publishing its assets.
RUN php artisan vendor:publish --tag=cachet --force


# ---------------------------------------------------------
# Runtime
# ---------------------------------------------------------

FROM base

WORKDIR /var/www/html

COPY --from=build /var/www/html /var/www/html

# Runtime directories required by Laravel/Cachet.
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

COPY docker/entrypoint.sh /usr/local/bin/cachet-entrypoint

RUN chmod +x /usr/local/bin/cachet-entrypoint

EXPOSE 80

ENTRYPOINT ["cachet-entrypoint"]

CMD ["apache2-foreground"]