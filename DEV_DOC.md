# Developer Documentation — Inception Project

This document explains how to develop, build, and manage the Inception infrastructure.

## Prerequisites

### System Requirements

- **OS:** Linux (VM or native)
- **Docker:** Engine 20.10+ with Compose plugin 2.0+
- **Tools:** make, bash, curl, openssl
- **Base OS:** Debian bookworm-slim (used in all Dockerfiles)

### Installation

```bash
# Install Docker (Ubuntu/Debian)
sudo apt update
sudo apt install -y docker.io docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Add user to docker group (optional, to avoid sudo)
sudo usermod -aG docker $USER
newgrp docker
```

## Project Structure

```
inception/
├── Makefile                    # Build & deployment automation
├── README.md                   # Project overview (for everyone)
├── USER_DOC.md                 # User guide (non-technical)
├── DEV_DOC.md                  # This file
├── .gitignore                  # Git exclusions (secrets, .env)
├── inception_subject.pdf       # Assignment specifications
│
├── secrets/                    # Credentials (NOT in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
│
└── srcs/                       # Source code & configuration
    ├── .env                    # Environment variables (NOT in git)
    ├── docker-compose.yml      # Service definitions
    │
    └── requirements/           # Service-specific code
        ├── mariadb/
        │   ├── Dockerfile      # MariaDB image
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── entrypoint.sh
```

## Environment Setup

### 1. Create Secrets Directory

```bash
mkdir -p secrets
```

Generate secure passwords:
```bash
# Generate random 32-character passwords
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt

# View them
cat secrets/db_password.txt
```

### 2. Create Environment File

```bash
cp srcs/.env.example srcs/.env  # Or create manually
```

**srcs/.env** should contain:
```bash
# Domain
DOMAIN_NAME=ana-pdos.42.fr

# Database
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=inception
DB_USER=wordpress_user

# WordPress Admin
WP_TITLE=My WordPress Site
WP_ADMIN_USER=webmaster
WP_ADMIN_EMAIL=ana-pdos@example.com

# WordPress Editor User
WP_USER=editor
WP_USER_EMAIL=editor@example.com
```

**Important:** Never commit `.env` or `secrets/` to git!

Check `.gitignore` contains:
```
secrets/
srcs/.env
```

## Build & Deployment

### Build Images

```bash
# Build all services (runs with compose up --build)
make up

# Build only specific service
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml build wordpress
```

### Lifecycle Commands

```bash
# Start stack (build if needed)
make up

# Check status
make ps

# View logs (all services)
make logs

# View specific service logs
docker compose -f srcs/docker-compose.yml logs nginx

# Stop services (preserve data)
make stop

# Start stopped services
make start

# Stop and remove containers (preserve volumes)
make down

# Complete cleanup (delete volumes and data)
make fclean

# Rebuild from scratch
make re
```

## Architecture & Design Decisions

### Network

```
┌─────────────────────────────────────────────┐
│  inception (Docker network - bridge mode)   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐    ┌───────────┐             │
│  │  nginx   │───→│ wordpress │             │
│  │ :443     │    │ :9000     │             │
│  └──────────┘    └─────┬─────┘             │
│                        │                   │
│                  ┌─────▼──────┐            │
│                  │  mariadb   │            │
│                  │  :3306     │            │
│                  └────────────┘            │
│                                             │
└─────────────────────────────────────────────┘

 Port 443 exposed to host
 All services communicate via DNS (container name)
 No --link or network: host used
```

### Docker Volumes (Named, Not Bind Mounts)

**Why named volumes?**
- Subject requirement (bind mounts forbidden for persistent storage)
- Better performance than bind mounts
- Easier to manage permissions
- Data stored at: `/home/ana-pdos/data/`

**Two volumes:**

1. **vol-mariadb** → `/home/ana-pdos/data/mariadb`
   - MariaDB data directory: `/var/lib/mysql`
   - Contains: database files, tables, indexes

2. **vol-wordpress** → `/home/ana-pdos/data/wordpress`
   - WordPress directory: `/var/www/html`
   - Contains: core files, themes, plugins, uploads

**Verify volumes:**
```bash
docker volume ls
docker volume inspect vol-wordpress
ls -la /home/ana-pdos/data/
```

### Secrets Management

**Why Docker Secrets?**
- Credentials never in `.env` or Dockerfiles
- Passed securely to containers
- Not visible in `docker inspect` output
- Subject recommendation

**How secrets work:**
```
secrets/db_password.txt
        ↓
docker-compose.yml defines it
        ↓
Container reads from /run/secrets/db_password
        ↓
Entrypoint script uses: $(cat /run/secrets/db_password)
```

**Create new secret:**
```bash
echo "my-password" > secrets/new_secret.txt

# Add to docker-compose.yml:
# secrets:
#   new_secret:
#     file: ../secrets/new_secret.txt
```

### Service Details

#### MariaDB

**Dockerfile strategy:**
- Base: `debian:bookworm-slim`
- Install: `mariadb-server` only
- No other packages

**Initialization:**
- Entrypoint creates DB if missing
- Two users: root + application user
- Application user can't contain "admin" (subject rule)
- Listens on 0.0.0.0:3306

**Health check:**
```bash
mariadb-admin ping -h localhost -u root -p"$password" --silent
```

**Data persistence:**
- All data in `/var/lib/mysql`
- Mounted to `vol-mariadb` (named volume)

#### WordPress + php-fpm

**Dockerfile strategy:**
- Base: `debian:bookworm-slim`
- Install: php8.2-fpm, php extensions, wp-cli
- Download: Latest WordPress from official source
- No nginx (forbidden per subject)

**Initialization:**
- Waits for MariaDB health check
- Creates `wp-config.php` if missing
- Installs WordPress via wp-cli
- Creates admin + editor user
- Sets up rewrite rules

**Service details:**
- Runs: `php-fpm -F` (foreground, PID 1)
- Listens: 0.0.0.0:9000 (FastCGI)
- Data: `/var/www/html`

#### NGINX

**Dockerfile strategy:**
- Base: `debian:bookworm-slim`
- Install: nginx, openssl
- Generate self-signed certificate during build
- Only TLS 1.2 and 1.3

**Configuration:**
- Listens: 0.0.0.0:443 (HTTPS only)
- No HTTP (subject requirement)
- Proxies PHP to wordpress:9000
- Caches static assets

**Certificate:**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/C=PT/ST=Lisbon/L=Lisbon/O=42/OU=student/CN=ana-pdos.42.fr"
```

### Entrypoint Scripts (No Infinite Loops)

**Subject requirement:** No `tail -f`, `sleep infinity`, or `while true`

**Correct approach:**
- Use `exec` to replace shell with main process
- Let container exit if process crashes
- Let Docker restart policy handle it

**Example (NGINX):**
```bash
exec nginx -g 'daemon off;'
# Not: tail -f /dev/null
```

**Example (php-fpm):**
```bash
exec php-fpm -F
# Not: php-fpm && sleep infinity
```

## Database Management

### Access MariaDB

```bash
# Via docker compose
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p

# Or with password file
PASSWORD=$(cat secrets/db_root_password.txt)
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p"$PASSWORD"

# Run SQL directly
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u root -p"$PASSWORD" -e "SHOW DATABASES;"
```

### WordPress Database

```bash
# Connect to WordPress database
PASSWORD=$(cat secrets/db_password.txt)
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u wordpress_user -p"$PASSWORD" inception

# List tables
SHOW TABLES;

# Query users
SELECT ID, user_login, user_email, user_registered FROM wp_users;

# Query posts
SELECT ID, post_title, post_status, post_date FROM wp_posts WHERE post_type='post';
```

## WordPress Management

### Access WordPress Container

```bash
docker compose -f srcs/docker-compose.yml exec wordpress bash
```

### WP-CLI Commands

```bash
# From host
docker compose -f srcs/docker-compose.yml exec wordpress wp --allow-root [command]

# List plugins
docker compose -f srcs/docker-compose.yml exec wordpress wp plugin list --allow-root

# Install plugin
docker compose -f srcs/docker-compose.yml exec wordpress wp plugin install hello-dolly --activate --allow-root

# List users
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --allow-root

# Change password
docker compose -f srcs/docker-compose.yml exec wordpress wp user update 1 --prompt=user_pass --allow-root
```

## Debugging & Troubleshooting

### View Dockerfile Build Output

```bash
docker compose -f srcs/docker-compose.yml build --no-cache nginx
```

### Container Shell Access

```bash
# NGINX
docker compose -f srcs/docker-compose.yml exec nginx bash

# WordPress
docker compose -f srcs/docker-compose.yml exec wordpress bash

# MariaDB
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### Check Container Logs

```bash
# All services
docker compose -f srcs/docker-compose.yml logs -f

# Specific service (follow mode)
docker compose -f srcs/docker-compose.yml logs -f nginx

# Last 50 lines
docker compose -f srcs/docker-compose.yml logs --tail=50 wordpress

# Timestamps
docker compose -f srcs/docker-compose.yml logs -f --timestamps
```

### Inspect Networks

```bash
# List networks
docker network ls

# Inspect inception network
docker network inspect inception

# Test DNS from container
docker compose -f srcs/docker-compose.yml exec nginx ping mariadb
```

### Inspect Volumes

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect vol-wordpress

# Check mount point
mount | grep docker

# Browse volume data
ls -la /home/ana-pdos/data/wordpress
ls -la /home/ana-pdos/data/mariadb
```

### Container Resource Usage

```bash
# Real-time stats
docker stats

# One-time snapshot
docker ps --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}"
```

## Testing & Validation

### Smoke Tests

```bash
# 1. All containers running?
make ps | grep "Up"

# 2. NGINX responding?
curl -k https://ana-pdos.42.fr/

# 3. WordPress installed?
curl -k https://ana-pdos.42.fr/wp-admin/ | head -20

# 4. Database accessible?
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp db check --allow-root

# 5. All users exist?
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp user list --allow-root --format=csv
```

### Port & Network Tests

```bash
# Port 443 listening?
netstat -tlnp | grep 443

# Container can reach MariaDB?
docker compose -f srcs/docker-compose.yml exec wordpress \
  nc -zv mariadb 3306

# DNS resolution?
docker compose -f srcs/docker-compose.yml exec wordpress \
  nslookup mariadb
```

## Performance & Optimization

### Reduce Image Size

Current approach is good:
- Use `slim` variants of base OS
- Use `--no-install-recommends`
- Multi-stage builds (if needed)
- Remove build dependencies after installation

### Database Optimization

```bash
# Enable query logs
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u root -p -e "SET GLOBAL general_log = 'ON';"

# Check slow queries
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u root -p -e "SHOW GLOBAL STATUS LIKE 'slow_queries';"
```

## Common Issues & Solutions

### Issue: "Connection refused" (NGINX → WordPress)

**Cause:** WordPress container not ready
**Solution:**
```bash
# Check health
make ps

# View logs
docker compose -f srcs/docker-compose.yml logs wordpress

# Restart
make down && make up
```

### Issue: "Cannot connect to database"

**Cause:** MariaDB not initialized or credentials wrong
**Solution:**
```bash
# Verify secrets exist
ls -la secrets/

# Check MariaDB health
make ps

# View MariaDB logs
docker compose -f srcs/docker-compose.yml logs mariadb

# Verify .env matches secrets
cat srcs/.env
cat secrets/db_password.txt
```

### Issue: "Certificate verification failed"

**Cause:** Self-signed certificate
**Solution:**
```bash
# Using curl
curl -k https://ana-pdos.42.fr

# Using browser
Click Advanced → Proceed anyway
```

## Next Steps & Resources

- [WordPress Developer Handbook](https://developer.wordpress.org/)
- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

