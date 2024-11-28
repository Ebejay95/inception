FROM debian:buster

RUN apt-get update && apt-get install -y \
	php7.3-fpm \
	php7.3-mysql \

COPY conf/www.conf /etc/php/7.3/fpm/pool.d/
COPY tools/wp-setup.sh /usr/local/bin/

EXPOSE 9000

CMD ["php-fpm7.3", "-F"]