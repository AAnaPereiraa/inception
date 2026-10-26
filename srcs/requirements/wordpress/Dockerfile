FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		mariadb-client \
		php8.2 \
		php8.2-cli \
		php8.2-fpm \
		php8.2-mbstring \
		php8.2-mysql \
		php8.2-xml \
		php8.2-curl \
		php8.2-zip \
		php8.2-gd \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html \
	&& curl -fsSL https://wordpress.org/latest.tar.gz \
		| tar -xz -C /var/www/html --strip-components=1 \
	&& curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
		-o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp \
	&& ln -sf /usr/sbin/php-fpm8.2 /usr/sbin/php-fpm \
	&& chown -R www-data:www-data /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
