#!/bin/bash

# Logging function to write to stderr
log_message() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')]: $1" >&2
}

log_message "Starting WordPress setup script..."

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

check_mariadb() {
	log_message "Checking MariaDB connection..."
	# Capture output of mysqladmin command
	MYSQLADMIN_OUT=$(mysqladmin ping -h mariadb --silent 2>&1)
	MYSQLADMIN_STATUS=$?
	if [ $MYSQLADMIN_STATUS -eq 0 ]; then
		log_message "MariaDB ping successful!"
		return 0
	else
		# Check if netcat is available and try socket connection
		NC_CHECK=$(command -v nc 2>&1)
		if [ -n "$NC_CHECK" ]; then
			NC_RESULT=$(nc -z mariadb 3306 2>&1)
			NC_STATUS=$?
			if [ $NC_STATUS -eq 0 ]; then
				log_message "Socket connection to MariaDB successful, trying ping again..."
				MYSQLADMIN_OUT=$(mysqladmin ping -h mariadb --silent 2>&1)
				MYSQLADMIN_STATUS=$?
				if [ $MYSQLADMIN_STATUS -eq 0 ]; then
					log_message "MariaDB ping successful!"
					return 0
				fi
			fi
		fi
	fi
	log_message "MariaDB not yet available..."
	return 1
}

wait_for_mariadb_and_setup() {
	local count=0
	local max_attempts=120

	# Just check if nc exists, don't redirect output
	command -v nc

	log_message "Waiting for MariaDB to be ready..."
	while [ $count -lt $max_attempts ]; do
		count=$((count + 1))
		if check_mariadb; then
			break
		else
			if [ $((count % 10)) -eq 0 ]; then
				log_message "Waiting for MariaDB... (Attempt $count/$max_attempts)"
			fi
			sleep 2
		fi
		if [ $count -ge $max_attempts ]; then
			log_message "Maximum attempts reached. Could not connect to MariaDB."
			return 1
		fi
	done

	log_message "Checking if database exists..."
	# Capture the output of the mysql command
	DB_CHECK=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>&1)
	MYSQL_STATUS=$?

	if [ $MYSQL_STATUS -eq 0 ]; then
		log_message "Database connection successful!"
		DB_LIKE=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>&1)
		if echo "$DB_LIKE" | grep -q "${MYSQL_DATABASE}"; then
			log_message "Database '${MYSQL_DATABASE}' exists."
		else
			log_message "Database '${MYSQL_DATABASE}' does not exist. Attempting to create..."
			create_attempts=0
			create_max_attempts=10

			while [ $create_attempts -lt $create_max_attempts ]; do
				create_attempts=$((create_attempts + 1))
				log_message "Creating database... (Attempt $create_attempts/$create_max_attempts)"

				CREATE_OUTPUT=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" 2>&1)
				CREATE_STATUS=$?
				if [ $CREATE_STATUS -eq 0 ]; then
					log_message "Database created successfully!"
					return 0
				else
					log_message "Create database error: $CREATE_OUTPUT"
				fi

				sleep 5

				if ! check_mariadb; then
					inner_count=0
					inner_max=30
					log_message "Lost connection to MariaDB, reconnecting..."
					while [ $inner_count -lt $inner_max ]; do
						inner_count=$((inner_count + 1))
						if check_mariadb; then
							log_message "Reconnected to MariaDB!"
							break
						fi
						sleep 2
					done
				fi
			done

			DB_CHECK_AGAIN=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>&1)
			if echo "$DB_CHECK_AGAIN" | grep -q "${MYSQL_DATABASE}"; then
				log_message "Database '${MYSQL_DATABASE}' now exists."
				return 0
			else
				log_message "Failed to create database '${MYSQL_DATABASE}'."
				return 1
			fi
		fi
	else
		log_message "Could not connect to database. Error: $DB_CHECK"
		return 1
	fi

	return 0
}

log_message "Starting MariaDB setup..."
wait_for_mariadb_and_setup
MARIADB_SETUP_STATUS=$?
if [ $MARIADB_SETUP_STATUS -ne 0 ]; then
	log_message "MariaDB setup failed with status $MARIADB_SETUP_STATUS"
	log_message "Continuing anyway, will retry later..."
fi

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
	log_message "No WordPress installation found. Setting up..."
	cd /var/www/html

	log_message "Downloading WordPress core..."
	WP_DOWNLOAD_OUTPUT=$(wp core download --allow-root 2>&1)
	DOWNLOAD_STATUS=$?
	if [ $DOWNLOAD_STATUS -ne 0 ]; then
		log_message "WordPress download failed with status $DOWNLOAD_STATUS"
		log_message "Error: $WP_DOWNLOAD_OUTPUT"
		log_message "Attempting alternate download method..."
		WGET_OUTPUT=$(wget https://wordpress.org/latest.tar.gz 2>&1)
		WGET_STATUS=$?
		if [ $WGET_STATUS -eq 0 ]; then
			TAR_OUTPUT=$(tar -xzf latest.tar.gz 2>&1)
			CP_OUTPUT=$(cp -a wordpress/. /var/www/html/ 2>&1)
			RM_OUTPUT=$(rm -rf wordpress latest.tar.gz 2>&1)
			log_message "Alternate download completed."
		else
			log_message "All download methods failed. Error: $WGET_OUTPUT"
			log_message "Continuing anyway, but WordPress may not work properly."
		fi
	else
		log_message "WordPress core downloaded successfully."
	fi

	log_message "Setting permissions..."
	chown -R www-data:www-data /var/www/html

	log_message "Ensuring database is ready..."
	wait_for_mariadb_and_setup
	DB_READY_STATUS=$?
	if [ $DB_READY_STATUS -ne 0 ]; then
		log_message "Database setup failed with status $DB_READY_STATUS"
		log_message "Will try to continue anyway..."
	fi

	log_message "Creating WordPress config..."
	config_attempts=0
	max_config_attempts=10

	while [ $config_attempts -lt $max_config_attempts ]; do
		config_attempts=$((config_attempts + 1))
		log_message "Creating wp-config.php... (Attempt $config_attempts/$max_config_attempts)"

		CONFIG_OUTPUT=$(wp config create --allow-root \
			--dbname=${MYSQL_DATABASE} \
			--dbuser=${MYSQL_USER} \
			--dbpass=${MYSQL_PASSWORD} \
			--dbhost=mariadb \
			--path=/var/www/html 2>&1)

		CONFIG_STATUS=$?
		if [ $CONFIG_STATUS -eq 0 ]; then
			log_message "wp-config.php created successfully!"
			break
		else
			log_message "Config creation failed with status $CONFIG_STATUS"
			log_message "Error: $CONFIG_OUTPUT"
			sleep 2
		fi
	done

	if [ ! -f /var/www/html/wp-config.php ]; then
		log_message "wp-config.php still doesn't exist. Creating manually..."
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
		log_message "Manual wp-config.php created."
	fi

	log_message "Ensuring database is ready for installation..."
	wait_for_mariadb_and_setup

	log_message "Installing WordPress..."
	install_attempts=0
	max_install_attempts=10

	while [ $install_attempts -lt $max_install_attempts ]; do
		install_attempts=$((install_attempts + 1))
		log_message "Running WordPress installer... (Attempt $install_attempts/$max_install_attempts)"

		DB_USE_OUTPUT=$(mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>&1)
		DB_USE_STATUS=$?

		if [ $DB_USE_STATUS -eq 0 ]; then
			log_message "Database access successful."
			log_message "Running core install..."
			INSTALL_OUTPUT=$(wp core install --allow-root \
				--url=${DOMAIN_NAME} \
				--title="${WP_TITLE}" \
				--admin_user=${WP_ADMIN_USER} \
				--admin_password=${WP_ADMIN_PASSWORD} \
				--admin_email=${WP_ADMIN_EMAIL} \
				--path=/var/www/html 2>&1)

			INSTALL_STATUS=$?
			if [ $INSTALL_STATUS -eq 0 ]; then
				log_message "WordPress installation successful!"
				break
			else
				log_message "WordPress installation failed with status $INSTALL_STATUS"
				log_message "Error: $INSTALL_OUTPUT"
			fi
		else
			log_message "Cannot access database for installation. Error: $DB_USE_OUTPUT"
		fi
		sleep 5
	done

	if [ $install_attempts -lt $max_install_attempts ]; then
		log_message "Creating additional user..."
		USER_CREATE_OUTPUT=$(wp user create --allow-root \
			${WP_USER} ${WP_USER_EMAIL} \
			--user_pass=${WP_USER_PASSWORD} \
			--role=author \
			--path=/var/www/html 2>&1)

		USER_CREATE_STATUS=$?
		if [ $USER_CREATE_STATUS -eq 0 ]; then
			log_message "Additional user created successfully!"
		else
			log_message "Additional user creation failed with status $USER_CREATE_STATUS"
			log_message "Error: $USER_CREATE_OUTPUT"
		fi
	else
		log_message "WordPress installation failed after $max_install_attempts attempts."
	fi
else
	log_message "WordPress already installed."
fi

log_message "Setting final permissions..."
chown -R www-data:www-data /var/www/html

log_message "Setting directory permissions..."
CHMOD_DIR_OUTPUT=$(find /var/www/html -type d -exec chmod 755 {} \; 2>&1)
CHMOD_DIR_STATUS=$?
if [ $CHMOD_DIR_STATUS -ne 0 ]; then
	log_message "Directory permissions error: $CHMOD_DIR_OUTPUT"
fi

log_message "Setting file permissions..."
CHMOD_FILE_OUTPUT=$(find /var/www/html -type f -exec chmod 644 {} \; 2>&1)
CHMOD_FILE_STATUS=$?
if [ $CHMOD_FILE_STATUS -ne 0 ]; then
	log_message "File permissions error: $CHMOD_FILE_OUTPUT"
fi

log_message "WordPress setup completed. Starting PHP-FPM..."
exec php-fpm7.4 -F