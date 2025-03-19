FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	php7.4-fpm \
	php7.4-mysql \
	wget \
	curl \
	mariadb-client

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /run/php
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

WORKDIR /var/www/html
RUN wget https://wordpress.org/latest.tar.gz \
	&& tar -xzf latest.tar.gz \
	&& rm latest.tar.gz \
	&& mv wordpress/* . \
	&& rmdir wordpress

COPY ./tools/wp-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config.sh

RUN chown -R www-data:www-data /var/www/html

CMD ["/usr/local/bin/wp-config.sh"]
