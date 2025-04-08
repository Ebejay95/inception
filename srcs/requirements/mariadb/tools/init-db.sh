#!/bin/bash

# Logdatei einrichten
LOG_FILE="/var/log/mariadb-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting MariaDB initialization script"

# Secrets als Umgebungsvariablen einlesen
echo "$(date): Reading secrets"
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
echo "$(date): MYSQL_PASSWORD read (not showing for security)"
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
echo "$(date): MYSQL_ROOT_PASSWORD read (not showing for security)"
echo "$(date): MYSQL_DATABASE=${MYSQL_DATABASE}"
echo "$(date): MYSQL_USER=${MYSQL_USER}"

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "$(date): Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "$(date): Starting MariaDB service temporarily..."
    service mariadb start

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
        # Wichtige Änderung hier - '%' erlaubt Verbindungen von überall
        mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
        echo "$(date): Granting privileges to user"
        mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"

        echo "$(date): Setting root password"
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

        echo "$(date): Flushing privileges"
        mysql -e "FLUSH PRIVILEGES;"

        # List all users to verify
        echo "$(date): Verifying users:"
        mysql -e "SELECT User, Host FROM mysql.user;"

        # List all databases to verify
        echo "$(date): Verifying databases:"
        mysql -e "SHOW DATABASES;"

        echo "$(date): Stopping temporary MariaDB service..."
        service mariadb stop
    else
        echo "$(date): ERROR - MariaDB did not start properly. Skipping database setup."
    fi
else
    echo "$(date): MariaDB data directory already initialized."
    echo "$(date): Checking existing configuration:"

    # Start temporary service to check configuration
    service mariadb start
    sleep 5

    # Try to connect as root and list users
    echo "$(date): Trying to check users with root:"
    if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user;" 2>/dev/null; then
        echo "$(date): Successfully connected as root"
    else
        echo "$(date): Failed to connect as root"
    fi

    # Try to connect as WordPress user
    echo "$(date): Trying to check access with WordPress user:"
    if mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null; then
        echo "$(date): Successfully connected as ${MYSQL_USER}"
    else
        echo "$(date): Failed to connect as ${MYSQL_USER}"
    fi

    service mariadb stop
fi

echo "$(date): Starting MariaDB server..."
exec mysqld_safe --user=mysql