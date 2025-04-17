#!/bin/bash

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

for i in {1..30}; do
	if mysqladmin ping -h mariadb --silent || (command -v nc && nc -z mariadb 3306 && mysqladmin ping -h mariadb --silent); then
		break
	fi

	if [ $i -eq 30 ]; then
		exit 1
	fi

	sleep 2
done

mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
	cd /var/www/html

	if ! wp core download --allow-root; then
		wget https://wordpress.org/latest.tar.gz
		tar -xzf latest.tar.gz
		cp -a wordpress/. .
		rm -rf wordpress latest.tar.gz
	fi

	if ! wp config create --allow-root \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" \
		--dbhost="mariadb"; then

		cat > /var/www/html/wp-config.php <<EOF
<?php
define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${MYSQL_PASSWORD}');
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         '$(openssl rand -hex 32)');
define('SECURE_AUTH_KEY',  '$(openssl rand -hex 32)');
define('LOGGED_IN_KEY',    '$(openssl rand -hex 32)');
define('NONCE_KEY',        '$(openssl rand -hex 32)');
define('AUTH_SALT',        '$(openssl rand -hex 32)');
define('SECURE_AUTH_SALT', '$(openssl rand -hex 32)');
define('LOGGED_IN_SALT',   '$(openssl rand -hex 32)');
define('NONCE_SALT',       '$(openssl rand -hex 32)');

\$table_prefix = 'wp_';
define('WP_DEBUG', false);

if (!defined('ABSPATH')) {
	define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF
	fi

	for i in {1..5}; do
		if wp core install --allow-root \
			--url=${DOMAIN_NAME} \
			--title="${WP_TITLE}" \
			--admin_user=${WP_ADMIN_USER} \
			--admin_password=${WP_ADMIN_PASSWORD} \
			--admin_email=${WP_ADMIN_EMAIL} \
			--path=/var/www/html; then

			break
		fi

		sleep 2
	done

	wp user create --allow-root \
		${WP_USER} ${WP_USER_EMAIL} \
		--user_pass=${WP_USER_PASSWORD} \
		--role=author \
		--path=/var/www/html
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

exec php-fpm7.4 -F