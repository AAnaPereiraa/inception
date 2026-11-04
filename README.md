*This project has been created as part of the 42 curriculum by ana-pdos.*

# Inception

Run WordPress behind NGINX (HTTPS only) with MariaDB, using **your own** Alpine/Debian images + Compose + named volumes + a private Docker network — all started from a root **Makefile**.

---

## Project Goal

Virtualize a small infrastructure (NGINX + WordPress/php-fpm + MariaDB) with Docker Compose on a VM, without pulling ready-made service images from Docker Hub.

---

## Folder layout

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
    └── wp_user_password.txt           
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

`.gitignore` so secrets and `.env` never get committed:

```gitignore
secrets/
srcs/.env
```

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
# add secrets folder inside project repository
# add .env file inside project srcs folder 


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

**Key Takeaway:**
AI was used as a productivity tool to reduce repetitive configuration tasks and generate templates, but every significant design decision and security-related choice was made by the developer and verified through testing.

---

## Project Description

This project builds a small WordPress infrastructure from the source files in
this repository instead of relying on ready-made service images. Docker Compose
starts three services on a private bridge network:

- **NGINX** terminates HTTPS on port 443 and serves the WordPress site.
- **WordPress** runs PHP through **php-fpm** and connects to MariaDB.
- **MariaDB** stores the WordPress database and is monitored by a healthcheck
  before WordPress starts.

Docker is used to package each service with its own dependencies and
configuration, while Compose defines how the services are built, started,
connected, and persisted. The `Makefile` provides a consistent entry point for
building the images, creating host data directories, starting and stopping the
stack, viewing logs, and cleaning up resources.

### Sources Included in the Project

The project includes all of the source and configuration needed to build the
infrastructure:

- `srcs/docker-compose.yml` defines the services, build contexts, environment
  variables, secrets, healthcheck, network, ports, and persistent storage.
- `srcs/requirements/nginx/` contains the NGINX Dockerfile, HTTPS configuration,
  and entrypoint script.
- `srcs/requirements/wordpress/` contains the WordPress/php-fpm Dockerfile,
  php-fpm configuration, and entrypoint script.
- `srcs/requirements/mariadb/` contains the MariaDB Dockerfile, database
  configuration, and initialization entrypoint script.
- `Makefile` automates the most common Docker Compose operations.
- `srcs/.env` contains non-secret configuration values such as service and
  database names. It is intentionally excluded from version control.
- `secrets/` contains password files supplied to containers as Docker secrets.
  These files are local credentials and must not be committed.
- `USER_DOC.md` and `DEV_DOC.md` provide additional usage and development
  guidance.

### Main Design Choices

- **One service per container:** NGINX, WordPress/php-fpm, and MariaDB are
  separated so that each component has a clear responsibility and can be
  rebuilt or maintained independently.
- **Custom images:** Each image is built from the Dockerfiles in the repository,
  making the installed packages and configuration explicit and reproducible.
- **Private service network:** The services communicate over the user-defined
  `inception` bridge network. Only NGINX publishes a host port, so the database
  is not exposed directly.
- **HTTPS at the edge:** NGINX is the public entry point and handles TLS,
  while WordPress and MariaDB remain internal services.
- **Persistent data:** Named volumes preserve MariaDB data and WordPress files
  when containers are recreated. The volumes use local bind-backed storage
  under `/home/ana-pdos/data`.
- **Secrets separated from configuration:** Passwords are mounted as files
  under `/run/secrets/`, while ordinary settings are loaded from `.env`.
- **Startup dependency management:** WordPress waits for MariaDB's healthcheck,
  reducing failures caused by trying to connect before the database is ready.

### Technology Comparisons

#### Virtual Machines vs Docker

| Virtual Machines | Docker |
|---|---|
| Virtualize a complete guest operating system, including its kernel. | Share the host kernel and isolate applications as lightweight containers. |
| Usually require more CPU, memory, disk space, and startup time. | Generally start faster and use fewer resources because containers package processes and dependencies rather than a full OS. |
| Provide stronger hardware-level isolation and can run a different operating system kernel. | Provide process-level isolation and are convenient for packaging and reproducing this multi-service application. |
| A good choice when full OS isolation or a different kernel is required. | The choice for this project because the services need reproducible environments and simple Compose-based orchestration. |

This project still runs Docker on a Linux VM, which provides the host
environment while Docker provides application-level isolation.

#### Secrets vs Environment Variables

| Secrets | Environment Variables |
|---|---|
| Intended for sensitive values such as passwords and can be mounted as files with controlled access. | Convenient for ordinary configuration such as database names, usernames, and hostnames. |
| Avoid placing credentials directly in Compose definitions or process environment listings. | May be visible through container inspection, diagnostics, or child processes, so they are not ideal for passwords. |
| Used here for database and WordPress passwords under `/run/secrets/`. | Used here through `srcs/.env` for non-sensitive configuration. |

Secrets do not make a credential safe if the host file is exposed, so the files
in `secrets/` must still be protected and excluded from version control.

#### Docker Network vs Host Network

| Docker Network | Host Network |
|---|---|
| Gives containers a private, isolated network and Docker DNS service discovery. | Places containers directly on the host's network namespace. |
| Services can reach one another by Compose service name, such as `mariadb`. | Removes much of the network isolation and can create port conflicts with host applications. |
| Allows only explicitly published ports to be reachable from the host. | Uses the host interfaces directly and generally requires less network translation. |

The project uses the user-defined `inception` bridge network so that NGINX,
WordPress, and MariaDB can communicate internally while only NGINX publishes
port 443.

#### Docker Volumes vs Bind Mounts

| Docker Volumes | Bind Mounts |
|---|---|
| Managed by Docker and normally stored in Docker's data directory. | Map a specific host path directly into a container or volume. |
| Portable and convenient when the host location should be abstracted away. | Give explicit control over where data is stored and make host backup or inspection straightforward. |
| Usually require Docker commands to locate and manage the underlying files. | Depend on the host path, its permissions, and its availability. |

The Compose file declares named volumes, `vol-mariadb` and `vol-wordpress`,
but configures their local driver with `type: none` and `o: bind`. This combines
Docker's volume lifecycle and service syntax with explicit storage under
`/home/ana-pdos/data`, so database and WordPress data survive container
recreation and can be managed by the `Makefile`.
