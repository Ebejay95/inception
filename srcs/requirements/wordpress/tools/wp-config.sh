#!/bin/bash

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

check_mariadb() {
	MYSQLADMIN_OUT=$(mysqladmin ping -h mariadb --silent 2>&1)
	MYSQLADMIN_STATUS=$?
	if [ $MYSQLADMIN_STATUS -eq 0 ]; then
		return 0
	else
		NC_CHECK=$(command -v nc 2>&1)
		if [ -n "$NC_CHECK" ]; then
			NC_RESULT=$(nc -z mariadb 3306 2>&1)
			NC_STATUS=$?
			if [ $NC_STATUS -eq 0 ]; then
				MYSQLADMIN_OUT=$(mysqladmin ping -h mariadb --silent 2>&1)
				MYSQLADMIN_STATUS=$?
				if [ $MYSQLADMIN_STATUS -eq 0 ]; then
					return 0
				fi
			fi
		fi
	fi
	return 1
}

wait_for_mariadb_and_setup() {
	local count=0
	local max_attempts=120

	command -v nc

	while [ $count -lt $max_attempts ]; do
		count=$((count + 1))
		if check_mariadb; then
			break
		else
			if [ $((count % 10)) -eq 0 ]; then
				sleep 2
			fi
		fi
		if [ $count -ge $max_attempts ]; then
			return 1
		fi
	done

	DB_CHECK=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>&1)
	MYSQL_STATUS=$?

	if [ $MYSQL_STATUS -eq 0 ]; then
		DB_LIKE=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>&1)
		if echo "$DB_LIKE" | grep -q "${MYSQL_DATABASE}"; then
			:
		else
			create_attempts=0
			create_max_attempts=10

			while [ $create_attempts -lt $create_max_attempts ]; do
				create_attempts=$((create_attempts + 1))

				CREATE_OUTPUT=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" 2>&1)
				CREATE_STATUS=$?
				if [ $CREATE_STATUS -eq 0 ]; then
					return 0
				fi

				sleep 5

				if ! check_mariadb; then
					inner_count=0
					inner_max=30
					while [ $inner_count -lt $inner_max ]; do
						inner_count=$((inner_count + 1))
						if check_mariadb; then
							break
						fi
						sleep 2
					done
				fi
			done

			DB_CHECK_AGAIN=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>&1)
			if echo "$DB_CHECK_AGAIN" | grep -q "${MYSQL_DATABASE}"; then
				return 0
			else
				return 1
			fi
		fi
	else
		return 1
	fi

	return 0
}

wait_for_mariadb_and_setup
MARIADB_SETUP_STATUS=$?

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
	cd /var/www/html

	WP_DOWNLOAD_OUTPUT=$(wp core download --allow-root 2>&1)
	DOWNLOAD_STATUS=$?
	if [ $DOWNLOAD_STATUS -ne 0 ]; then
		WGET_OUTPUT=$(wget https://wordpress.org/latest.tar.gz 2>&1)
		WGET_STATUS=$?
		if [ $WGET_STATUS -eq 0 ]; then
			TAR_OUTPUT=$(tar -xzf latest.tar.gz 2>&1)
			CP_OUTPUT=$(cp -a wordpress/. /var/www/html/ 2>&1)
			RM_OUTPUT=$(rm -rf wordpress latest.tar.gz 2>&1)
		fi
	fi

	chown -R www-data:www-data /var/www/html

	wait_for_mariadb_and_setup
	DB_READY_STATUS=$?

	config_attempts=0
	max_config_attempts=10

	while [ $config_attempts -lt $max_config_attempts ]; do
		config_attempts=$((config_attempts + 1))

		CONFIG_OUTPUT=$(wp config create --allow-root \
			--dbname=${MYSQL_DATABASE} \
			--dbuser=${MYSQL_USER} \
			--dbpass=${MYSQL_PASSWORD} \
			--dbhost=mariadb \
			--path=/var/www/html 2>&1)

		CONFIG_STATUS=$?
		if [ $CONFIG_STATUS -eq 0 ]; then
			break
		else
			sleep 2
		fi
	done

	if [ ! -f /var/www/html/wp-config.php ]; then
		cat > /var/www/html/wp-config.php <<EOF
<?php
define( 'DB_NAME', '${MYSQL_DATABASE}' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         '$(openssl rand -hex 32)' );
define( 'SECURE_AUTH_KEY',  '$(openssl rand -hex 32)' );
define( 'LOGGED_IN_KEY',    '$(openssl rand -hex 32)' );
define( 'NONCE_KEY',        '$(openssl rand -hex 32)' );
define( 'AUTH_SALT',        '$(openssl rand -hex 32)' );
define( 'SECURE_AUTH_SALT', '$(openssl rand -hex 32)' );
define( 'LOGGED_IN_SALT',   '$(openssl rand -hex 32)' );
define( 'NONCE_SALT',       '$(openssl rand -hex 32)' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
	fi

	wait_for_mariadb_and_setup

	install_attempts=0
	max_install_attempts=10

	while [ $install_attempts -lt $max_install_attempts ]; do
		install_attempts=$((install_attempts + 1))

		DB_USE_OUTPUT=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>&1)
		DB_USE_STATUS=$?

		if [ $DB_USE_STATUS -eq 0 ]; then
			INSTALL_OUTPUT=$(wp core install --allow-root \
				--url=${DOMAIN_NAME} \
				--title="${WP_TITLE}" \
				--admin_user=${WP_ADMIN_USER} \
				--admin_password=${WP_ADMIN_PASSWORD} \
				--admin_email=${WP_ADMIN_EMAIL} \
				--path=/var/www/html 2>&1)

			INSTALL_STATUS=$?
			if [ $INSTALL_STATUS -eq 0 ]; then
				break
			fi
		fi
		sleep 5
	done

	if [ $install_attempts -lt $max_install_attempts ]; then
		USER_CREATE_OUTPUT=$(wp user create --allow-root \
			${WP_USER} ${WP_USER_EMAIL} \
			--user_pass=${WP_USER_PASSWORD} \
			--role=author \
			--path=/var/www/html 2>&1)
	fi
else
	:
fi

chown -R www-data:www-data /var/www/html

CHMOD_DIR_OUTPUT=$(find /var/www/html -type d -exec chmod 755 {} \; 2>&1)
CHMOD_FILE_OUTPUT=$(find /var/www/html -type f -exec chmod 644 {} \; 2>&1)

exec php-fpm7.4 -F