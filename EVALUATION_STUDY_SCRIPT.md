# Inception Evaluation Study Script

This is a rehearsal guide for the 42 Inception correction rubric. Replace
`ana-pdos` and `ana-pdos.42.fr` with the evaluated student's login and domain
when practicing on another repository.

## 0. Before the defense

- Clone the repository into an empty directory.
- Confirm that the repository belongs to the student and that the expected
  files are present at the root.
- The student must be present for the defense and must explain the work.
- Do not print passwords in the terminal or commit `.env` and secret files.
- Check that the repository contains no credentials outside the evaluation
  `.env` and secret setup.

Expected root layout:

```text
Makefile
srcs/
  docker-compose.yml
  requirements/
    nginx/Dockerfile
    wordpress/Dockerfile
    mariadb/Dockerfile
```

## 1. Clean Docker before starting

The rubric asks for this cleanup before evaluation. It removes all local
containers, images, volumes, and networks, so only run it on the evaluation
VM:

```bash
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network prune -f
```

The default `bridge`, `host`, and `none` networks are protected by Docker and
must remain. `docker network prune -f` removes unused custom networks without
trying to delete those defaults.

Check the repository before building:

```bash
find . -maxdepth 3 -type f | sort
git status --short
```

## 2. Run the hard-failure checks first

Read `srcs/docker-compose.yml`, the Makefile, every Dockerfile, and every
entrypoint script. Stop the evaluation if a mandatory stop condition is met.

```bash
grep -RInE 'network:[[:space:]]*host|links:|--link|tail[[:space:]]+-f|sleep[[:space:]]+infinity|while[[:space:]]+true' . \
  --exclude-dir=.git --exclude='*.md'
```

Verify manually:

- `srcs` is at the repository root.
- A root `Makefile` exists.
- Compose has a user-defined `networks:` section.
- There is no `network: host`, `links:`, or `--link`.
- Each service has its own non-empty Dockerfile.
- Dockerfiles use a permitted, pinned Alpine or Debian base image.
- Entrypoints run the real service in the foreground with `exec`; no
  `tail -f`, infinite loop, or background service is used.
- WordPress does not install or run NGINX.
- MariaDB does not install or run NGINX.

## 3. Inspect the design and explain it

Use these commands:

```bash
sed -n '1,240p' Makefile
sed -n '1,260p' srcs/docker-compose.yml
find srcs/requirements -type f -maxdepth 4 -print -exec sed -n '1,220p' {} \;
```

Explain the architecture in this order:

```text
Browser --HTTPS:443--> nginx --FastCGI:9000--> wordpress/php-fpm
                                             |
                                             +--MySQL:3306--> mariadb
```

Short answers to memorize:

**How does Docker work?** Docker packages a process, its dependencies, and
configuration into an image. A container is a running isolated process made
from that image. Containers share the host kernel but have isolated files,
processes, and networks.

**How does Compose work?** Compose reads the YAML file and creates the
services, networks, volumes, dependencies, environment, and restart policies
as one application. `docker compose up` builds images when requested and
starts the services together.

**Image with Compose versus without Compose:** An image is the same reusable
template in both cases. Without Compose, each `docker run` needs manual
options for ports, mounts, networks, and environment. Compose stores that
relationship in one reproducible YAML file and creates the complete stack.

**Docker versus virtual machines:** Containers start faster and use less
disk and memory because they share the host kernel. A VM includes a complete
guest operating system and gives stronger OS-level isolation.

**Why this directory structure?** The root Makefile is the entry point, `srcs`
contains all application configuration, and each service owns its Dockerfile,
configuration, and startup script. This keeps build responsibilities separate
and makes the Compose file reproducible.

## 4. Build and start through the Makefile

Run the project using the required entry point:

```bash
make
make ps
docker compose -f srcs/docker-compose.yml ps
```

Expected result:

- `mariadb`, `wordpress`, and `nginx` are running.
- Images are built locally from the three student Dockerfiles.
- The Compose network exists.
- No service has crashed or is repeatedly restarting.

Useful follow-up commands:

```bash
docker images
docker network ls
docker network inspect inception
docker compose -f srcs/docker-compose.yml logs --tail=100 nginx wordpress mariadb
```

## 5. Test NGINX and HTTPS

Set the domain on the evaluation VM if needed:

```bash
grep -q 'ana-pdos.42.fr' /etc/hosts || \
  echo '127.0.0.1 ana-pdos.42.fr' | sudo tee -a /etc/hosts
```

Check that only HTTPS is exposed:

```bash
docker compose -f srcs/docker-compose.yml port nginx 443
curl -I --max-time 5 http://ana-pdos.42.fr:80
curl -k -I https://ana-pdos.42.fr/
```

Expected result:

- Port 443 maps to the NGINX container.
- HTTP port 80 cannot be used to reach the site.
- HTTPS returns the configured WordPress site, not the WordPress installer.
- A self-signed certificate warning is acceptable.

Demonstrate TLS versions:

```bash
openssl s_client -connect ana-pdos.42.fr:443 -tls1_2 </dev/null 2>/dev/null | grep 'Protocol'
openssl s_client -connect ana-pdos.42.fr:443 -tls1_3 </dev/null 2>/dev/null | grep 'Protocol'
```

Explain that NGINX terminates TLS on 443 and forwards PHP requests to the
WordPress container over the private Docker network. TLS 1.2 and 1.3 are
enabled; the certificate need not be publicly trusted for this project.

## 6. Test WordPress and php-fpm

Open these URLs in a browser:

```text
https://ana-pdos.42.fr/
https://ana-pdos.42.fr/wp-admin/
```

Verify all of the following:

- The site is already installed and configured.
- The administrator username does not contain `admin` or `administrator`.
- The regular user can log in and add a comment.
- The administrator can log in, edit a page, save it, and the public page
  shows the change.

Inspect the process and WordPress users if needed:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress ps -ef
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --allow-root
docker compose -f srcs/docker-compose.yml exec wordpress wp db check --allow-root
```

Explain that WordPress runs PHP through php-fpm on port 9000. NGINX serves
the public request and sends `.php` requests to php-fpm using FastCGI.

## 7. Test MariaDB and its volume

Never put a password directly into this document or into shell history. Use
the secret file only on the evaluation machine:

```bash
docker volume ls
docker volume inspect vol-mariadb
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

At the password prompt, enter the root password from the local secret file.
Then run these SQL statements inside MariaDB:

```sql
SHOW DATABASES;
USE inception;
SHOW TABLES;
SELECT ID, user_login FROM wp_users;
```

Expected result:

- A named MariaDB volume exists and its host path contains
  `/home/ana-pdos/data/`.
- The WordPress database is not empty.
- The student can explain the database login and the difference between the
  root account and the WordPress application account.

## 8. Test the WordPress volume

```bash
docker volume inspect vol-wordpress
ls -la /home/ana-pdos/data/wordpress
```

Expected result:

- A named WordPress volume exists.
- Its host path contains `/home/ana-pdos/data/`.
- It contains the WordPress files, including `wp-config.php` after setup.

## 9. Test persistence

Record a visible page edit before this test. Then reboot the VM:

```bash
sudo reboot
```

After the VM returns:

```bash
cd /path/to/inception
make
make ps
curl -k -I https://ana-pdos.42.fr/
```

Confirm that the site still works, the database is configured, and the page
edit and users are still present. Explain that the containers are disposable,
while the named volumes hold WordPress files and MariaDB data on the host.

## 10. Bonus evaluation

Only do this after every mandatory item passes. For each bonus service:

1. Identify its Dockerfile, Compose service, network connection, and volume.
2. Start and test the service using its documented interface.
3. Ask the student to explain how it works and why it is useful.

Do not award bonus points if the mandatory part is incomplete or malfunctioning.

## 11. Final result

Before assigning a grade, record:

- Mandatory checks passed or failed.
- Any hard-failure flag: empty work, incomplete work, cheat, crash,
  concerning situation, or inability to explain the code.
- Bonus services that were actually tested.
- The final rating from 0 to 5.

## Repository-specific preparation notes

For this checkout, verify these points before the defense:

- The actual Dockerfiles use `debian:bookworm-slim`. Confirm that this is the
  permitted penultimate stable Debian version at the time of evaluation; the
  rubric is version-sensitive.
- The root `.gitignore` ignores `secrets/` and `srcs/.env`; verify those files
  remain untracked before sharing or committing the project.
- The local `secrets/` directory and `srcs/.env` are currently untracked,
  which is appropriate for local setup. Do not add them to Git.
- The Compose volumes use named volumes with host-backed driver options. Be
  ready to show both `docker volume inspect` output and the host directories.
- The repository currently has no bonus service, so mandatory behavior is the
  focus.