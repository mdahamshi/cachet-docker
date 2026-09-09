#!/bin/bash

set -e

cd /var/www/html

echo "Starting Cachet..."

mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

chown -R www-data:www-data \
    storage \
    bootstrap/cache

chmod -R ug+rwx \
    storage \
    bootstrap/cache

echo "Waiting for database..."

if [ -n "${DB_HOST:-}" ]; then
    until php -r '
        $host = getenv("DB_HOST");
        $port = getenv("DB_PORT") ?: "3306";

        $connection = @fsockopen(
            $host,
            (int) $port,
            $errno,
            $errstr,
            2
        );

        if ($connection) {
            fclose($connection);
            exit(0);
        }

        exit(1);
    '; do
        echo "Database is not ready..."
        sleep 2
    done
fi

echo "Database is available."

php artisan migrate --force

echo "Cachet is ready."

exec "$@"