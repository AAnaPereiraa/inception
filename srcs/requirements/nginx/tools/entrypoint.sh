#!/bin/bash
set -e

sed -i "s/listen 443 ssl/listen ${NGINX_PORT} ssl/g" /etc/nginx/nginx.conf
sed -i "s/listen \[::\]:443 ssl/listen [::]:${NGINX_PORT} ssl/g" /etc/nginx/nginx.conf
sed -i "s/fastcgi_pass wordpress:9000/fastcgi_pass wordpress:${WP_PORT}/g" /etc/nginx/nginx.conf

echo "==> NGINX will be launched on port ${NGINX_PORT}"
nginx -t
nginx -g 'daemon off;'