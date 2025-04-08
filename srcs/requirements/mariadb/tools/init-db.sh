#!/bin/bash

# Secrets als Umgebungsvariablen einlesen
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing MariaDB data directory..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql

	echo "Starting MariaDB service temporarily..."
	service mariadb start

	echo "Waiting for MariaDB to be ready..."
	for i in {1..30}; do
		if mysqladmin ping >/dev/null 2>&1; then
			break
		fi
		echo "Waiting for MariaDB to be ready... $i/30"
		sleep 1
	done

	if mysqladmin ping >/dev/null 2>&1; then
		echo "MariaDB is ready. Setting up database and users..."

		echo "Creating database: ${MYSQL_DATABASE}"
		mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

		echo "Creating user: ${MYSQL_USER}"
		# Wichtige Änderung hier - '%' erlaubt Verbindungen von überall
		mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
		mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"

		echo "Setting root password"
		mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
		mysql -e "FLUSH PRIVILEGES;"

		echo "Stopping temporary MariaDB service..."
		service mariadb stop
	else
		echo "MariaDB did not start properly. Skipping database setup."
	fi
else
	echo "MariaDB data directory already initialized."
fi

echo "Starting MariaDB server..."
exec mysqld_safe --user=mysql