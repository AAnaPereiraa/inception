#!/bin/bash

set -e

DB_PASSWORD="$(cat /run/secrets/db_password 2>/dev/null)"
DB_PASSWORD="${DB_PASSWORD:-1234}"

DB_ADMIN_PASSWORD="$(cat /run/secrets/db_admin_password 2>/dev/null)"
DB_ADMIN_PASSWORD="${DB_ADMIN_PASSWORD:-1234}"

DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password 2>/dev/null)"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-1234}"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld --user=mysql --bootstrap << EOF

FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS ${DB_NAME};

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

CREATE USER IF NOT EXISTS '${DB_ADMIN}'@'%' IDENTIFIED BY '${DB_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_ADMIN}'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

EOF
fi

echo "==> MariaDB will be launched on port ${DB_PORT}"
exec mysqld --user=mysql
