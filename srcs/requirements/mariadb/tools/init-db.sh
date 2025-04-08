#!/bin/bash

LOG_FILE="/var/log/mariadb-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting MariaDB initialization script"

echo "$(date): Reading secrets"
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
echo "$(date): MYSQL_PASSWORD read (not showing for security)"
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
echo "$(date): MYSQL_ROOT_PASSWORD read (not showing for security)"
echo "$(date): MYSQL_DATABASE=${MYSQL_DATABASE}"
echo "$(date): MYSQL_USER=${MYSQL_USER}"

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "$(date): Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "$(date): Starting MariaDB service temporarily..."
    mysqld --user=mysql &
    MYSQLD_PID=$!

    echo "$(date): Waiting for MariaDB to be ready..."
    for i in {1..30}; do
        if mysqladmin ping >/dev/null 2>&1; then
            echo "$(date): MariaDB is ready after $i attempts."
            break
        fi
        echo "$(date): Waiting for MariaDB to be ready... $i/30"
        sleep 1
    done

    if mysqladmin ping >/dev/null 2>&1; then
        echo "$(date): MariaDB is ready. Setting up database and users..."

        echo "$(date): Creating database: ${MYSQL_DATABASE}"
        mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

        echo "$(date): Creating user: ${MYSQL_USER}"
        mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
        mysql -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"

        echo "$(date): Granting privileges to user"
        mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
        mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';"

        echo "$(date): Setting root password"
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

        echo "$(date): Flushing privileges"
        mysql -e "FLUSH PRIVILEGES;"

        echo "$(date): Verifying users:"
        mysql -e "SELECT User, Host FROM mysql.user;"

        echo "$(date): Verifying databases:"
        mysql -e "SHOW DATABASES;"

        echo "$(date): Stopping temporary MariaDB service..."
        kill $MYSQLD_PID
        wait $MYSQLD_PID
    else
        echo "$(date): ERROR - MariaDB did not start properly. Skipping database setup."
        kill $MYSQLD_PID 2>/dev/null || true
    fi
else
    echo "$(date): MariaDB data directory already initialized."
    echo "$(date): Checking existing configuration:"

    echo "$(date): Starting MariaDB temporarily for checks..."
    mysqld --user=mysql &
    MYSQLD_PID=$!

    for i in {1..30}; do
        if mysqladmin ping >/dev/null 2>&1; then
            echo "$(date): MariaDB is ready after $i attempts."
            break
        fi
        echo "$(date): Waiting for MariaDB to be ready for checks... $i/30"
        sleep 1
    done

    echo "$(date): Trying to check users with root:"
    if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user;" 2>/dev/null; then
        echo "$(date): Successfully connected as root"
    else
        echo "$(date): Failed to connect as root"
    fi

    echo "$(date): Trying to check access with WordPress user:"
    if mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null; then
        echo "$(date): Successfully connected as ${MYSQL_USER}"

        if mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>/dev/null | grep -q "${MYSQL_DATABASE}"; then
            echo "$(date): ${MYSQL_DATABASE} database exists."
        else
            echo "$(date): ${MYSQL_DATABASE} database does not exist. Creating..."
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
            echo "$(date): Created ${MYSQL_DATABASE} database."
        fi
    else
        echo "$(date): Failed to connect as wp_user"

        echo "$(date): Fixing user permissions..."
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" 2>/dev/null
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" 2>/dev/null
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';" 2>/dev/null
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;" 2>/dev/null

        echo "$(date): User permissions updated."
    fi

    echo "$(date): Stopping temporary MariaDB instance..."
    kill $MYSQLD_PID
    wait $MYSQLD_PID || true
fi

chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

echo "$(date): Starting MariaDB server..."
exec mysqld_safe --user=mysql