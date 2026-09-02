*This project has been created as part of the 42 curriculum by ana-pdos.*

# Inception — Step-by-step guide

Run WordPress behind NGINX (HTTPS only) with MariaDB, using **your own** Alpine/Debian images + Compose + named volumes + a private Docker network — all started from a root **Makefile**.

> Subject version: 5.3  
> Login: `ana-pdos` · Domain: `ana-pdos.42.fr`

---

## Goal (one sentence)

Virtualize a small infrastructure (NGINX + WordPress/php-fpm + MariaDB) with Docker Compose on a VM, without pulling ready-made service images from Docker Hub.

---

## Phase 0 — Environment

1. Work **inside a Virtual Machine** (subject requirement).
2. Install Docker Engine + Docker Compose plugin.
3. Confirm Docker works:
   - `docker run hello-world`
4. Pick a base OS for all images: **penultimate stable Alpine or Debian** (same choice for every service is fine).
5. Note your 42 login → domain will be `ana-pdos.42.fr`.

---

## Phase 1 — Folder layout (scaffold first)

Create this tree (matches the subject):

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt          # or similar; keep out of git
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            └── tools/
```

**Do this first:** write `.gitignore` so secrets and `.env` never get committed:

```gitignore
secrets/
srcs/.env
**/credentials*
```

---

## Phase 2 — Secrets & env (before any Dockerfile)

1. Put **passwords only** in `secrets/*.txt` (one secret per file).
2. Put **non-secret config** in `srcs/.env`, e.g.:
   - `DOMAIN_NAME=ana-pdos.42.fr`
   - `MYSQL_USER=...` (must not contain `admin` / `administrator`)
   - DB name, WP titles, etc.
3. Rules:
   - **No passwords in Dockerfiles**
   - **No passwords in git**
   - Prefer Docker secrets for confidential values (subject strongly recommends this)
   - Never use image tag `latest`
   - It is mandatory to use environment variables and a `.env` file

---

## Phase 3 — MariaDB container (build DB first)

Order matters: WordPress needs a DB.

1. Write `mariadb/Dockerfile`:
   - `FROM` Alpine/Debian (pinned version, not `latest`)
   - Install MariaDB server only
   - Copy conf + entrypoint
2. Config (`conf/`): listen on the container network; data dir under a path you’ll mount as a volume.
3. Entrypoint script must:
   - Init DB if empty
   - Create WordPress DB + user from env/secrets
   - Create **root** password from secrets
   - **exec** `mariadbd` / `mysqld` as PID 1  
     (no `tail -f`, `sleep infinity`, `while true`, or `bash` as main process)
4. Test alone later with Compose once the service exists.

---

## Phase 4 — WordPress + php-fpm (no nginx here)

1. Dockerfile: install php-fpm + required PHP extensions (mysqli, etc.), download/configure WordPress (or install via `wp-cli` in the entrypoint).
2. Entrypoint:
   - Wait until MariaDB is reachable
   - Install/configure WP if not already installed
   - Create **2 users**: one admin (username must **not** contain `admin`/`administrator`), one regular user
   - **exec** `php-fpm` in foreground (`-F`)
3. Conf: php-fpm listens on a port or socket that NGINX can reach **over the Docker network** (TCP `9000` is common).

---

## Phase 5 — NGINX + TLS (only public entry)

1. Dockerfile: install nginx + openssl (or mount certs you generate).
2. Generate a self-signed cert for `ana-pdos.42.fr` (often in entrypoint if missing).
3. `nginx.conf`:
   - Listen **443 only**
   - TLS **1.2 and/or 1.3 only**
   - `fastcgi_pass` to the WordPress php-fpm service name
   - Serve WP files from the shared WordPress volume
4. Entrypoint: start nginx in **foreground** (`daemon off;` / `nginx -g 'daemon off;'`).
5. **Only** this container publishes host port `443`.

---

## Phase 6 — `docker-compose.yml`

Wire everything:

| Requirement | How |
|---|---|
| One container per service | `nginx`, `wordpress`, `mariadb` |
| Image name = service name | `image: nginx` etc., built from your Dockerfiles |
| Custom network | `networks:` present; **no** `network: host`, **no** `links:` |
| Restart on crash | `restart: always` (or `unless-stopped`) |
| WP files volume | named volume → host `/home/ana-pdos/data/wordpress` |
| DB volume | named volume → host `/home/ana-pdos/data/mariadb` |
| No bind mounts for those two | use named volumes + `driver_opts` (`device` / `o` / `type`) to pin host path |
| Secrets / env | `env_file: .env` + `secrets:` |

Create host dirs before up:

```bash
mkdir -p /home/ana-pdos/data/wordpress /home/ana-pdos/data/mariadb
```

---

## Phase 7 — Makefile (root)

Typical targets:

- `all` / `up` → `docker compose -f srcs/docker-compose.yml up -d --build`
- `down` → stop/remove containers
- `clean` → down + remove images/volumes (be careful)
- `fclean` / `re` as you prefer
- Create `/home/ana-pdos/data/...` if missing

Compose must be invoked **from the Makefile**; Dockerfiles are called via Compose `build:`.

---

## Phase 8 — Domain name on the VM

1. Edit `/etc/hosts`:
   ```text
   127.0.0.1   ana-pdos.42.fr
   ```
2. Open `https://ana-pdos.42.fr` (accept self-signed warning).
3. Confirm login works for both WP users; admin name has no `admin` substring.

---

## Phase 9 — Hard rules checklist (fail points)

Before defense, verify:

- [ ] Own Dockerfiles only (no Hub WordPress/nginx/mariadb images)
- [ ] Base = Alpine or Debian penultimate stable, **no `latest`**
- [ ] NGINX = only entry on **443** + TLS 1.2/1.3
- [ ] WP = php-fpm only; MariaDB = DB only
- [ ] Named volumes → `/home/ana-pdos/data/...`
- [ ] Custom Docker network
- [ ] `restart` policy set
- [ ] No `tail -f` / infinite sleep / `bash` as main process
- [ ] No passwords in Dockerfiles or git
- [ ] `.env` + secrets used
- [ ] Two WP users; admin name OK
- [ ] Containers restart after crash (`docker kill` test)

---

## Description

This project implements a complete WordPress infrastructure using **Docker and Docker Compose**. The goal is to learn system administration and containerization by building and managing:

- **NGINX** — Web server with HTTPS/TLS support only
- **WordPress + php-fpm** — Content management system with PHP FastCGI Process Manager
- **MariaDB** — Relational database for WordPress data

All services run in isolated Docker containers connected via a private Docker network, with persistent data stored in named volumes. The entire stack is orchestrated by Docker Compose and deployed via a Makefile.

### What You Learn

- Docker containerization and best practices
- Docker Compose orchestration and service networking
- System administration (security, volumes, secrets)
- NGINX configuration and TLS/SSL
- PHP-FPM configuration
- Database management (MariaDB/MySQL)
- Bash scripting and entrypoint design
- Makefile automation

---

## Instructions

### Prerequisites

- Linux VM with Docker Engine and Docker Compose plugin installed
- 4GB+ RAM, 20GB+ disk space
- Edit `/etc/hosts` to add: `127.0.0.1 ana-pdos.42.fr`

### Setup & Launch

```bash
# Clone repository
cd /home/ana-pdos/Core_Curriculum/GitHub/inception

# Generate passwords (if not already done)
mkdir -p secrets
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt

# Start the infrastructure
make up

# Verify all containers are running
make ps

# Access the website
# Browser: https://ana-pdos.42.fr
# Admin Panel: https://ana-pdos.42.fr/wp-admin
# Username: webmaster (see srcs/.env for admin user)
# Password: (see secrets/wp_admin_password.txt)
```

### Common Commands

```bash
make up       # Start services (build if needed)
make down     # Stop services (preserve data)
make logs     # View real-time logs
make ps       # Check container status
make clean    # Stop and remove containers
make fclean   # Full cleanup (delete volumes and data)
```

For detailed user and developer instructions, see [USER_DOC.md](USER_DOC.md) and [DEV_DOC.md](DEV_DOC.md).

---

## Resources

### Official Documentation

- **Docker:**
  - [Docker Documentation](https://docs.docker.com/) — Complete Docker reference
  - [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/) — Compose syntax
  - [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) — Dockerfile best practices

- **WordPress:**
  - [WordPress.org Documentation](https://wordpress.org/support/) — WordPress support
  - [WordPress Developer Handbook](https://developer.wordpress.org/) — For developers
  - [WP-CLI Documentation](https://developer.wordpress.org/cli/commands/) — Command-line interface

- **NGINX:**
  - [NGINX Documentation](https://nginx.org/en/docs/) — Official NGINX docs
  - [NGINX Admin Guide](https://nginx.org/en/docs/admin.html) — Administration guide
  - [NGINX TLS/SSL Configuration](https://nginx.org/en/docs/http/ngx_http_ssl_module.html) — SSL/TLS module

- **MariaDB:**
  - [MariaDB Knowledge Base](https://mariadb.com/kb/) — Official MariaDB reference
  - [MariaDB Administrators](https://mariadb.com/kb/en/documentation/#administration) — Admin documentation
  - [MySQL vs MariaDB](https://mariadb.com/kb/en/mysql-vs-mariadb/) — Compatibility guide

- **Bash/Shell Scripting:**
  - [GNU Bash Manual](https://www.gnu.org/software/bash/manual/) — Bash reference
  - [ShellCheck](https://www.shellcheck.net/) — Bash linter and best practices

### Key Concepts

- Docker Networking: https://docs.docker.com/network/
- Docker Volumes: https://docs.docker.com/storage/volumes/
- Docker Secrets: https://docs.docker.com/engine/swarm/secrets/
- PHP-FPM Configuration: https://www.php.net/manual/en/install.fpm.configuration.php
- Self-Signed Certificates: https://www.ssl.com/article/how-to-create-self-signed-certificates/

### Learning Resources

- Docker Getting Started: https://docs.docker.com/get-started/
- WordPress Hosting on Linux: https://wordpress.org/support/article/how-to-install-wordpress/
- System Administration Fundamentals: https://www.linux.com/training-tutorials/

### AI Usage in This Project

This project leverages AI tools (including GitHub Copilot) for the following:

**Tasks AI Was Used For:**
1. **Docker configuration assistance** — Dockerfile syntax, best practices, multi-stage builds
2. **Nginx configuration** — SSL/TLS setup, FastCGI proxying, security headers
3. **Bash scripting** — Entrypoint script logic, error handling, parameter validation
4. **Documentation** — README structure, troubleshooting guides, inline code comments
5. **Docker Compose optimization** — Service definitions, networking, volume management
6. **Database initialization** — SQL query generation, user creation, privilege setup

**Code/Decisions Verified By Human:**
- All Dockerfiles were reviewed for correctness and subject compliance
- Every entrypoint script tested to ensure proper PID 1 handling (no infinite loops)
- Docker Compose configuration validated against subject requirements
- Security decisions (TLS versions, user permissions) manually verified
- Database initialization logic tested with actual containers
- All AI-generated code was understood and explained before use

**Critical Areas NOT AI-Generated:**
- Architecture design and container networking strategy
- Security model (secrets vs environment variables)
- Volume strategy (named volumes vs bind mounts)
- Domain-specific requirements interpretation
- Testing and validation procedures

**Key Takeaway:**
AI was used as a productivity tool to reduce repetitive configuration tasks and generate templates, but every significant design decision and security-related choice was made by the developer and verified through testing.

---

## Project Description

### Architecture & Design

This project implements a classic **three-tier web application architecture** using Docker:

```
┌─────────────────┐
│  NGINX (443)    │  Reverse proxy / Web server
│  - TLS/SSL      │
└────────┬────────┘
         │ (FastCGI)
┌────────▼──────────────┐
│  WordPress + php-fpm  │  Application server
│  - PHP processing     │
└────────┬──────────────┘
         │ (TCP 3306)
┌────────▼──────────────┐
│  MariaDB               │  Data persistence
│  - Database           │
└───────────────────────┘
```

**Key Design Choices:**

1. **Debian base OS** — Chosen for stability and familiar package management
2. **Named volumes** — More secure than bind mounts, better permission handling
3. **Docker Compose network** — Automatic DNS for inter-container communication
4. **Docker secrets** — Credentials never in code or environment
5. **Single-purpose containers** — Each service has one clear role (Unix philosophy)
6. **Health checks** — WordPress waits for database readiness before starting
7. **Self-signed certificates** — Sufficient for development; demonstrates TLS knowledge

### Docker and Sources

**Why Docker?**
- Isolation: Services don't conflict with host or each other
- Portability: Run anywhere Docker is installed
- Reproducibility: Same image = same environment every time
- Scalability: Easy to add more instances
- Security: Limit resources and capabilities per container

**Sources Used:**
- **Base Images:** Debian bookworm-slim (lightweight, stable)
- **WordPress:** Downloaded directly from wordpress.org (never pulled pre-made image)
- **PHP-FPM:** Installed from Debian repositories
- **NGINX:** Installed from Debian repositories
- **MariaDB:** Installed from Debian repositories
- **Tools:** wp-cli, openssl, curl included where needed

---

### Architectural Comparisons

#### 1. Virtual Machines vs Docker Containers

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Resource Usage** | Heavy (GB of RAM per VM) | Lightweight (MB per container) |
| **Boot Time** | Minutes | Seconds |
| **Isolation** | Complete OS isolation | Process/namespace isolation |
| **Scalability** | Limited (VMs take space) | Easy (quick to spawn) |
| **Use Case** | Multiple OS types, legacy apps | Modern microservices |
| **Overhead** | Full kernel + OS per instance | Shared kernel (Linux) |
| **This Project** | Containers faster to develop | ✓ Chosen for learning flexibility |

**Why Containers Here?**
- Demonstrates modern DevOps practices
- Faster iteration during development
- Each service isolated without VM overhead
- Native support for Docker Compose orchestration

#### 2. Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|------------------------|
| **Security** | Encrypted, scoped to service | Plain text, visible everywhere |
| **Visibility** | Hidden from `docker inspect` | Visible in container inspection |
| **Git Safety** | Safe to version control | Must be .gitignored |
| **Use Case** | Passwords, API keys, tokens | Non-sensitive config |
| **Rotation** | Harder to rotate dynamically | Easy to change |
| **Swarm Mode** | Native support | Basic support |
| **This Project** | ✓ Used for passwords | ✓ Used for domain, usernames |

**Implementation in This Project:**
```
Passwords (SECRETS):
- db_password.txt          → /run/secrets/db_password
- db_root_password.txt     → /run/secrets/db_root_password
- wp_admin_password.txt    → /run/secrets/wp_admin_password

Config (ENV VARIABLES):
- srcs/.env contains:
  - DOMAIN_NAME
  - DB_HOST, DB_PORT, DB_NAME, DB_USER
  - WP_TITLE, WP_ADMIN_USER, WP_USER, etc.
```

**Best Practice Principle:** Anything confidential → Secrets; anything you'd share → Env vars.

#### 3. Docker Network vs Host Network

| Aspect | Docker Network (bridge) | Host Network |
|--------|-------------------------|--------------|
| **Isolation** | ✓ Containers isolated from host | ✗ Direct host access (no isolation) |
| **Inter-container DNS** | ✓ Automatic by name | ✗ Must use host IP + port mapping |
| **Port Conflicts** | ✓ Can reuse ports per container | ✗ Host ports must be unique |
| **Security** | ✓ Network segmentation | ✗ Wider attack surface |
| **Performance** | Slight overhead | ✓ Minimal overhead |
| **Swarm Mode** | ✓ Required for service discovery | Limited |
| **This Project** | ✓ Chosen for security | |

**Why Docker Network?**
- **Subject requirement:** Explicit network definition mandatory
- **Security:** nginx only talks to wordpress; wordpress only talks to mariadb
- **Flexibility:** Easy to add more services without changing IPs
- **DNS:** Containers reach each other by name (`wordpress:9000`)

**Alternative Rejected:**
```
# BAD: using network: host (not allowed by subject)
# - NGINX would bind to host:443 directly
# - Service discovery becomes manual
# - No network segmentation
```

#### 4. Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|--------------|------------|
| **Permissions** | ✓ Docker manages permissions | ✗ Host UID/GID issues |
| **Performance** | ✓ Optimized by Docker | ✗ Slower on Mac/Windows |
| **Backup** | ✓ Easy with `docker volume` | ✗ Manual backup needed |
| **Portability** | ✓ Works anywhere | ✗ Path dependent |
| **Data Ownership** | ✓ Consistent across systems | ✗ Can conflict with host |
| **Docker API** | ✓ Fully supported | ✗ Limited support |
| **This Project** | ✓ Chosen for wordpress + mariadb | |

**Implementation in This Project:**
```yaml
volumes:
  vol-mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ana-pdos/data/mariadb
  vol-wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ana-pdos/data/wordpress
```

**Why Named Volumes (Not Bind Mounts)?**
- Subject forbids bind mounts for persistent storage
- Better permission isolation (www-data user in container)
- Transparent backup/restore workflow
- Survives container/image deletion

**Data Persistence:**
```
Host:           /home/ana-pdos/data/wordpress  ←→  Container: /var/www/html
Host:           /home/ana-pdos/data/mariadb    ←→  Container: /var/lib/mysql
```

Both directories created by Makefile; volumes map them into containers.

---

## Technical Highlights

### Security Practices

1. **TLS 1.2/1.3 Only** — No legacy SSL versions
2. **Secrets in Files** — Not in .env or code
3. **User Separation** — WordPress runs as `www-data`, not root
4. **Database Isolation** — Dedicated user with minimal privileges
5. **No Public Services** — Only NGINX on port 443 exposed

### Performance Considerations

1. **Lightweight Base Images** — `*-slim` variants used
2. **Layer Caching** — Dockerfile instructions ordered by change frequency
3. **Multi-stage Builds** — Not needed here but recommended approach
4. **Static Asset Caching** — NGINX caches CSS/JS/images

### Reliability

1. **Health Checks** — WordPress waits for MariaDB to be ready
2. **Restart Policies** — Containers automatically restart on crash
3. **Proper Init Process** — Services use `exec` to become PID 1
4. **Error Handling** — Entrypoints check for failures and exit appropriately

---



---

## Phase 10 — Docs (mandatory)

Write in English:

1. **README.md** (this file — expand for evaluation)
   - First line italic: *This project has been created as part of the 42 curriculum by ana-pdos.*
   - Description, Instructions, Resources (+ how you used AI)
   - Extra “Project description”: Docker sources, design choices, and comparisons:
     - VM vs Docker
     - Secrets vs env vars
     - Docker network vs host network
     - Volumes vs bind mounts
2. **USER_DOC.md** — start/stop, open site/admin, credentials, health checks
3. **DEV_DOC.md** — from-scratch setup, Makefile/Compose, volumes, data location

---

## Phase 11 — Bonus (only after mandatory is solid)

Each bonus = own Dockerfile + container (+ volume if needed):

1. Redis cache for WP
2. FTP → WP files volume
3. Static site (not PHP)
4. Adminer
5. One extra service you can justify

The bonus part is evaluated **only** if the mandatory part is complete and works without malfunctions.

---

## Suggested build order (day by day)

| Day | Focus |
|---|---|
| 1 | VM + Docker + folder tree + `.gitignore` + secrets/`.env` |
| 2 | MariaDB image + Compose service + volume; verify DB persists |
| 3 | WordPress + php-fpm; connect to MariaDB; create users |
| 4 | NGINX + TLS + FastCGI to WP; domain in `/etc/hosts` |
| 5 | Makefile polish, restart/crash tests, secrets cleanup |
| 6 | README + USER_DOC + DEV_DOC |
| 7 | Bonuses if mandatory is clean |

---

## Architecture

```text
Browser → https://ana-pdos.42.fr:443
              │
           [nginx]  ← only published port
              │  FastCGI :9000
         [wordpress]  ← php-fpm + WP files volume
              │  MySQL :3306
          [mariadb]   ← DB volume
```

All three services run on one user-defined Docker network.

---

## Description

*(Fill in before evaluation: project goal and brief overview.)*

Inception is a system administration project that sets up a containerized LEMP-like stack (NGINX, WordPress with php-fpm, MariaDB) using custom Docker images and Docker Compose.

## Instructions

*(Fill in once the project runs: compile / install / run.)*

```bash
# Example (adjust when Makefile exists)
make
# then open https://ana-pdos.42.fr
```

## Resources

*(Fill in before evaluation.)*

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [NGINX TLS](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [MariaDB](https://mariadb.com/kb/en/documentation/)
- [WordPress / php-fpm](https://www.php.net/manual/en/install.fpm.php)

### AI usage

*(Describe which tasks AI helped with and which parts of the project.)*

---

## Project description (for evaluation)

*(Complete before defense.)*

### Main design choices

- …

### Virtual Machines vs Docker

- …

### Secrets vs Environment Variables

- …

### Docker Network vs Host Network

- …

### Docker Volumes vs Bind Mounts

- …
