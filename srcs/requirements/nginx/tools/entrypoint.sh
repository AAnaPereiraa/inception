#!/bin/bash
set -euo pipefail

echo "==> Checking NGINX configuration"
nginx -t

echo "==> Starting NGINX on port 443 (TLS)"
exec nginx -g 'daemon off;'
