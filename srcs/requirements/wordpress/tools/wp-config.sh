#!/bin/bash

# Secrets als Umgebungsvariablen einlesen
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Warten bis MariaDB erreichbar ist
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb --silent; do
	sleep 1
done
echo "MariaDB is available!"

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
	echo "WordPress files not found. Downloading WordPress..."
	cd /var/www/html
	wp core download --allow-root

	chown -R www-data:www-data /var/www/html

	echo "Creating wp-config.php..."
	wp config create --allow-root \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=${MYSQL_USER} \
		--dbpass=${MYSQL_PASSWORD} \
		--dbhost=mariadb \
		--path=/var/www/html

	echo "Installing WordPress core..."
	wp core install --allow-root \
		--url=${DOMAIN_NAME} \
		--title=${WP_TITLE} \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--path=/var/www/html

	echo "Creating additional user..."
	wp user create --allow-root \
		${WP_USER} ${WP_USER_EMAIL} \
		--user_pass=${WP_USER_PASSWORD} \
		--role=author \
		--path=/var/www/html

	echo "WordPress setup complete!"
fi

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F