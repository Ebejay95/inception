#!/bin/bash

while ! mysqladmin ping -h mariadb --silent; do
	sleep 1
done

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
	echo "WordPress files not found. Downloading WordPress..."
	cd /var/www/html
	wp core download --allow-root

	chown -R www-data:www-data /var/www/html

	wp config create --allow-root \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=${MYSQL_USER} \
		--dbpass=${MYSQL_PASSWORD} \
		--dbhost=mariadb \
		--path=/var/www/html

	wp core install --allow-root \
		--url=${DOMAIN_NAME} \
		--title=${WP_TITLE} \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--path=/var/www/html

	wp user create --allow-root \
		${WP_USER} ${WP_USER_EMAIL} \
		--user_pass=${WP_USER_PASSWORD} \
		--role=author \
		--path=/var/www/html
fi

exec php-fpm7.4 -F
