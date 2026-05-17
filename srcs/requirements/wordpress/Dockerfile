FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    wget \
    tar \
    php8.2 \
    php8.2-cli \
    php8.2-fpm \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-mysql \
    mariadb-client

RUN mkdir -p /var/www/html/

RUN wget https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz -C /var/www/html/ --strip-components=1 \
    && rm latest.tar.gz

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && mv wp-cli.phar /usr/bin/wp \
    && chmod +x /usr/bin/wp

RUN ln -s /usr/sbin/php-fpm8.2 /usr/sbin/php-fpm

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE $WP_PORT
VOLUME ["/var/www/html"]
ENTRYPOINT ["/entrypoint.sh"]