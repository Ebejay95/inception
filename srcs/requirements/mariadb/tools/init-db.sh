#!/bin/bash

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

	mysqld --user=mysql &
	MYSQLD_PID=$!

	for i in {1..30}; do
		if mysqladmin ping; then
			break
		fi
		sleep 1
	done

	MYSQL_ROOT_CHECK=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user;")
	MYSQL_USER_CHECK=$(mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;")

	if [ -n "$MYSQL_USER_CHECK" ]; then
		DB_EXISTS=$(mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';")
		if [ -z "$DB_EXISTS" ] || ! echo "$DB_EXISTS" | grep -q "${MYSQL_DATABASE}"; then
			mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
			mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
			mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
		fi
	else
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
	fi

	kill $MYSQLD_PID
	wait $MYSQLD_PID || true

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

exec mysqld_safe --user=mysql