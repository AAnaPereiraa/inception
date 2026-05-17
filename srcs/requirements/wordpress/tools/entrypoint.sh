#!/bin/bash
set -e

DB_PASSWORD="$(cat /run/secrets/db_password 2>/dev/null)"
DB_PASSWORD="${DB_PASSWORD:-1234}"
WP_PATH=/var/www/html

until mariadb -P "${DB_PORT}" -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" -e ";" 2>/dev/null; do
    echo "[wordpress] Waiting for MariaDB..."
    sleep 2
done

if [ ! -f "/var/www/html/wp-config.php" ]; then
    chown -R www-data:www-data /var/www/html
    chmod -R g+w /var/www/html/wp-content

    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;

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
        --role=subscriber \
        --allow-root

    wp rewrite structure '/%postname%/' --path=/var/www/html --allow-root
    wp rewrite flush --path=/var/www/html --allow-root
fi

sed -i "s/listen = 0.0.0.0:9000/listen = 0.0.0.0:${WP_PORT}/g" /etc/php/8.2/fpm/pool.d/www.conf
echo "==> WordPress will be launched on port ${WP_PORT}"
exec php-fpm -F