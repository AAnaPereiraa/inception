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
