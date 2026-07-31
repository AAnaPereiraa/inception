#!/bin/bash
set -euo pipefail

DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "==> Initializing MariaDB data directory"
	mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null

	mysqld --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
	echo "==> MariaDB initialized"
fi

echo "==> Starting MariaDB"
exec mysqld --user=mysql
