#!/bin/bash

WP_PATH="/var/www/html"

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	echo "Setting up WordPress..."

	mkdir -p "$WP_PATH"
	chown -R www-data:www-data "$WP_PATH"
	chmod -R 755 "$WP_PATH"

	cd "$WP_PATH"
	if [ ! -f "$WP_PATH/wp-login.php" ]; then
		wp core download --allow-root
	fi

	if [ ! -f "$WP_PATH/wp-config.php" ]; then
		wp config create \
			--dbname="$MYSQL_DATABASE" \
			--dbuser="$MYSQL_USER" \
			--dbpass="$DB_PASSWORD" \
			--dbhost=mariadb \
			--path="$WP_PATH" \
			--allow-root

		echo "Waiting for database connection..."
		max_retries=30
		counter=0
		until wp db check --allow-root || [ $counter -eq $max_retries ]; do
			echo "Waiting for database... attempt $counter of $max_retries"
			sleep 3
			counter=$((counter+1))
		done

		if [ $counter -eq $max_retries ]; then
			echo "Failed to connect to database after $max_retries attempts"
			exit 1
		fi

		wp core install \
			--url="$DOMAIN_NAME" \
			--title="$WP_TITLE" \
			--admin_user="$WP_ADMIN_USER" \
			--admin_password="$WP_ADMIN_PASSWORD" \
			--admin_email="$WP_ADMIN_EMAIL" \
			--path="$WP_PATH" \
			--allow-root

		wp user create "$WP_USER" "$WP_USER_EMAIL" \
			--user_pass="$WP_USER_PASSWORD" \
			--role=author \
			--allow-root

		echo "WordPress setup completed!"
	fi
fi

mkdir -p /run/php
chown -R www-data:www-data /run/php
chmod -R 755 /run/php

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F