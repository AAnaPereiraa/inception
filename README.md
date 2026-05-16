# Inception — 42 Berlin

This repository documents the **Inception** project from the 42 curriculum (42 Berlin), where the goal is to build a small, production-like infrastructure using **Docker** and **Docker Compose**.

## Project Goal

Inception teaches how to design and run a multi-service environment with isolated containers, custom images, persistent data, and secure service communication.

Typical requirements include:

- A custom Docker network for service communication
- Separate containers for each service
- Dockerfiles written by you (not only prebuilt images)
- Persistent volumes for database and WordPress data
- Proper restart policies and service dependencies
- No usage of insecure shortcuts (like `--link` or running everything in one container)

## Typical Architecture

The mandatory part usually includes:

- **NGINX** (TLS termination, reverse proxy)
- **WordPress + PHP-FPM**
- **MariaDB**

Bonus services often include things like:

- Redis cache
- FTP server
- Adminer
- Static website
- Monitoring stack

## What You Learn

- Containerization fundamentals
- Building images from Dockerfiles
- Managing services with Docker Compose
- Networking and inter-container communication
- Volumes and data persistence
- Basic system administration and troubleshooting

## How This Project Is Usually Evaluated at 42

- Correct service separation and container lifecycle
- Correct usage of volumes and networks
- Proper HTTPS setup (NGINX + TLS)
- Stable startup/restart behavior
- Clean, reproducible setup with documented commands

## Useful Commands (General Docker Workflow)

```bash
# Build and start the stack
docker compose up --build -d

# Check running services
docker compose ps

# Follow logs
docker compose logs -f

# Stop and remove containers
docker compose down
```

---

If you are a 42 student: adapt this README to match your exact project implementation and school-specific evaluation details.
