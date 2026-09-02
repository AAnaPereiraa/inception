# User Documentation — Inception Project

This document explains how to use the Inception infrastructure for end users and administrators.

## Overview — What This Project Does

This infrastructure provides a complete WordPress hosting environment with:
- **NGINX** — Web server with HTTPS (TLS 1.2/1.3) only
- **WordPress** — Blogging platform with php-fpm backend
- **MariaDB** — Database server
- All services isolated in Docker containers on a private network

## Quick Start

### Starting the Stack

```bash
cd /home/ana-pdos/Core_Curriculum/GitHub/inception
make up
```

This will:
1. Create the data directories
2. Build all Docker images
3. Start all containers
4. Initialize the database
5. Install WordPress

### Stopping the Stack

```bash
make down
```

Stops all containers but preserves data.

### Restarting Services

```bash
make start    # Restart after stopping
make stop     # Stop without removing
```

### Viewing Logs

```bash
make logs     # View real-time logs from all services
```

## Accessing the Website

### WordPress Frontend
- **URL:** `https://ana-pdos.42.fr`
- **Browser:** Visit this URL to see the WordPress homepage
- **Note:** Use HTTPS; self-signed certificate may trigger a browser warning

### WordPress Admin Panel
- **URL:** `https://ana-pdos.42.fr/wp-admin`
- **Username:** See credentials below
- **Password:** See credentials below

## Credentials & Security

### Finding Credentials

Passwords are stored in **`/home/ana-pdos/inception/secrets/`** directory:

```
secrets/
├── db_password.txt           # MySQL user password
├── db_root_password.txt      # MySQL root password
├── wp_admin_password.txt     # WordPress admin password
└── wp_user_password.txt      # WordPress editor user password
```

**To view a credential:**
```bash
cat ./secrets/db_password.txt
cat ./secrets/wp_admin_password.txt
```

### Default Users

**WordPress Admin User:**
- Username: `webmaster` (set in `.env`)
- Password: (see `secrets/wp_admin_password.txt`)
- Role: Administrator (full access)

**WordPress Editor User:**
- Username: `editor` (set in `.env`)
- Password: (see `secrets/wp_user_password.txt`)
- Role: Author (can write posts)

**Database Users:**
- Root user: Can manage the database
- Application user: Used by WordPress to access database

## Checking Service Status

### View Running Containers

```bash
make ps
```

This shows all containers and their status.

### Health Check — Is Everything Running?

All services should show `Up` status:
```
CONTAINER ID   IMAGE      STATUS
...            nginx      Up (healthy)
...            wordpress  Up (healthy)
...            mariadb    Up (healthy)
```

### Verify Services Are Responding

```bash
# Test NGINX (should show certificate details)
openssl s_client -connect ana-pdos.42.fr:443

# Test WordPress (should return HTML)
curl -k https://ana-pdos.42.fr

# Test MariaDB (check if WordPress can access database)
make logs | grep "WordPress installed"
```

## Managing Data

### WordPress Files Location

All WordPress files (themes, plugins, uploads) are stored in:
```
/home/ana-pdos/data/wordpress/
```

Changes in WordPress admin panel → saved to this volume.

### Database Location

MariaDB data is stored in:
```
/home/ana-pdos/data/mariadb/
```

All posts, pages, users, and settings are persisted here.

### Data Persistence

- Data **survives** container restarts
- Data **survives** `make down` (volumes are preserved)
- Data is **deleted** only by `make fclean`

## Troubleshooting

### HTTPS Certificate Warning

The certificate is self-signed for development. This is expected.
- **Browser:** Click "Advanced" → "Proceed anyway"
- **curl:** Use `-k` flag: `curl -k https://ana-pdos.42.fr`

### Cannot Connect to Website

1. Check containers are running: `make ps`
2. View logs: `make logs`
3. Restart stack: `make down && make up`

### WordPress Shows "Cannot Connect to Database"

1. Check MariaDB container is healthy: `make ps`
2. Check MariaDB logs: `make logs`
3. Verify credentials in `srcs/.env` match `secrets/` files
4. Restart: `make down && make up`

### Port Already in Use

NGINX uses port 443 (HTTPS). If it's busy:
```bash
# Find what's using port 443
sudo lsof -i :443

# Kill it if safe, or use a different port in docker-compose.yml
```

### Lost Database or WordPress Data

**Warning:** This deletes all data!
```bash
make fclean    # Complete cleanup
make up        # Rebuild from scratch
```

## Updating WordPress

To add plugins or themes:

1. **Via WordPress Admin Panel:**
   - Log in to `https://ana-pdos.42.fr/wp-admin`
   - Install from "Plugins" or "Themes" menu

2. **Via Command Line:**
   ```bash
   docker compose -f srcs/docker-compose.yml exec wordpress wp plugin install plugin-name --allow-root
   ```

## Backup & Restore

### Backup

```bash
# Backup WordPress files
cp -r /home/ana-pdos/data/wordpress/ /home/ana-pdos/wordpress_backup

# Backup database
docker compose -f srcs/docker-compose.yml exec mariadb mysqldump -u root -p$(cat secrets/db_root_password.txt) inception > /home/ana-pdos/inception_backup.sql
```

### Restore

```bash
# Restore WordPress files
cp -r /home/ana-pdos/wordpress_backup/* /home/ana-pdos/data/wordpress/

# Restore database
docker compose -f srcs/docker-compose.yml exec mariadb mysql -u root -p$(cat secrets/db_root_password.txt) inception < /home/ana-pdos/inception_backup.sql
```

## Support & Documentation

For more technical details, see:
- [DEV_DOC.md](DEV_DOC.md) — For developers
- [README.md](README.md) — Project overview and architecture
- Official docs:
  - [WordPress Handbook](https://developer.wordpress.org/)
  - [NGINX Documentation](https://nginx.org/en/docs/)
  - [MariaDB Knowledge Base](https://mariadb.com/kb/)
