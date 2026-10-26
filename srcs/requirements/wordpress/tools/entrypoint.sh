#!/bin/bash
set -euo pipefail

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"
WP_PATH=/var/www/html

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PORT:?DB_PORT is required}"
: "${WP_TITLE:?WP_TITLE is required}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

echo "==> Waiting for MariaDB at ${DB_HOST}:${DB_PORT}"
until mariadb -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" -e "SELECT 1;" >/dev/null 2>&1; do
	sleep 2
done
echo "==> MariaDB is ready"

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
	echo "==> Installing WordPress"
	chown -R www-data:www-data "${WP_PATH}"

	wp config create \
		--path="${WP_PATH}" \
		--dbname="${DB_NAME}" \
		--dbuser="${DB_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost="${DB_HOST}:${DB_PORT}" \
		--allow-root

	wp core install \
		--path="${WP_PATH}" \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root

	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--path="${WP_PATH}" \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=author \
		--allow-root

	wp rewrite structure '/%postname%/' --path="${WP_PATH}" --allow-root
	wp rewrite flush --path="${WP_PATH}" --allow-root
	echo "==> WordPress installed"
else
	echo "==> WordPress already configured"
fi

mkdir -p /run/php
echo "==> Starting php-fpm"
exec php-fpm -F
