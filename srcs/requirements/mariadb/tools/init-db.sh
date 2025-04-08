#!/bin/bash

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql

	mysqld --user=mysql &
	MYSQLD_PID=$!

	for i in {1..30}; do
		if mysqladmin ping || true; then
			break
		fi
		sleep 1
	done

	if mysqladmin ping || true; then
		mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
		mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
		mysql -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
		mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
		mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';"
		mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
		mysql -e "FLUSH PRIVILEGES;"

		mysqladmin shutdown
		wait $MYSQLD_PID
	else
		kill $MYSQLD_PID 2>&1 || true
	fi
else
	mysqld --user=mysql &
	MYSQLD_PID=$!

	for i in {1..30}; do
		if mysqladmin ping || true; then
			break
		fi
		sleep 1
	done

	mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user;" > /tmp/mysql_output 2>&1
	rm -f /tmp/mysql_output

	DB_USER_CAN_ACCESS=false
	if mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;"; then
		DB_USER_CAN_ACCESS=true
		if mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';"; then
			: # No-op command to avoid empty then clause
		else
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

	mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
	wait $MYSQLD_PID || true
fi

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

exec mysqld_safe --user=mysql