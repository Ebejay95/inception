#!/bin/bash

LOG_FILE="/var/log/wordpress-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting WordPress configuration script"

echo "$(date): Reading secrets"
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
echo "$(date): MYSQL_PASSWORD read (not showing for security)"
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
echo "$(date): WP_ADMIN_PASSWORD read (not showing for security)"
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
echo "$(date): WP_USER_PASSWORD read (not showing for security)"

echo "$(date): Environment variables:"
echo "$(date): DOMAIN_NAME=${DOMAIN_NAME}"
echo "$(date): WP_TITLE=${WP_TITLE}"
echo "$(date): MYSQL_DATABASE=${MYSQL_DATABASE}"
echo "$(date): MYSQL_USER=${MYSQL_USER}"

check_mariadb() {
    if mysqladmin ping -h mariadb --silent 2>/dev/null; then
        return 0
    elif command -v nc >/dev/null 2>&1 && nc -z mariadb 3306 2>/dev/null; then
        if mysqladmin ping -h mariadb --silent 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

wait_for_mariadb_and_setup() {
    local count=0
    local max_attempts=120

    echo "$(date): Waiting for MariaDB..."

    if command -v nc >/dev/null 2>&1; then
        echo "$(date): Using nc to check for MariaDB availability"
    else
        echo "$(date): nc command not found, using alternative check method"
    fi

    while [ $count -lt $max_attempts ]; do
        count=$((count + 1))
        echo "$(date): Waiting for MariaDB... attempt $count/$max_attempts"

        if check_mariadb; then
            echo "$(date): MariaDB service is reachable."
            break
        else
            echo "$(date): MariaDB service is not yet available"
            sleep 2
        fi

        if [ $count -ge $max_attempts ]; then
            echo "$(date): ERROR - Max attempts reached. MariaDB is not accessible."
            return 1
        fi
    done

    echo "$(date): Testing database connection..."
    if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null; then
        echo "$(date): Successfully connected to MariaDB"

        if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>/dev/null | grep -q "${MYSQL_DATABASE}"; then
            echo "$(date): Database ${MYSQL_DATABASE} exists"
        else
            echo "$(date): Database ${MYSQL_DATABASE} does not exist. Creating it..."
            create_attempts=0
            create_max_attempts=10

            while [ $create_attempts -lt $create_max_attempts ]; do
                create_attempts=$((create_attempts + 1))
                echo "$(date): Attempting to create database (attempt $create_attempts/$create_max_attempts)..."

                if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" 2>/dev/null; then
                    echo "$(date): Successfully created database ${MYSQL_DATABASE}"
                    return 0
                fi

                echo "$(date): Failed to create database. Waiting for MariaDB to be fully ready..."
                sleep 5

                if ! check_mariadb; then
                    echo "$(date): MariaDB connection lost. Waiting for it to come back..."
                    inner_count=0
                    inner_max=30
                    while [ $inner_count -lt $inner_max ]; do
                        inner_count=$((inner_count + 1))
                        if check_mariadb; then
                            echo "$(date): MariaDB is back online."
                            break
                        fi
                        sleep 2
                        echo "$(date): Still waiting for MariaDB to come back... $inner_count/$inner_max"
                    done
                fi
            done

            if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>/dev/null | grep -q "${MYSQL_DATABASE}"; then
                echo "$(date): Database ${MYSQL_DATABASE} now exists"
                return 0
            else
                echo "$(date): ERROR - Failed to create or verify database ${MYSQL_DATABASE}"
                return 1
            fi
        fi
    else
        echo "$(date): ERROR - Failed to connect to MariaDB"
        return 1
    fi

    return 0
}

wait_for_mariadb_and_setup

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
    echo "$(date): WordPress files not found. Downloading WordPress..."
    cd /var/www/html
    wp core download --allow-root

    echo "$(date): Setting permissions"
    chown -R www-data:www-data /var/www/html

    echo "$(date): Ensuring database is ready before WordPress installation..."
    wait_for_mariadb_and_setup

    echo "$(date): Creating wp-config.php..."
    config_attempts=0
    max_config_attempts=10

    while [ $config_attempts -lt $max_config_attempts ]; do
        config_attempts=$((config_attempts + 1))
        echo "$(date): Creating wp-config.php (attempt $config_attempts/$max_config_attempts)..."

        if wp config create --allow-root \
            --dbname=${MYSQL_DATABASE} \
            --dbuser=${MYSQL_USER} \
            --dbpass=${MYSQL_PASSWORD} \
            --dbhost=mariadb \
            --path=/var/www/html; then

            echo "$(date): Successfully created wp-config.php"
            break
        else
            echo "$(date): Failed to create wp-config.php. Retrying..."
            sleep 2
        fi
    done

    if [ ! -f /var/www/html/wp-config.php ]; then
        echo "$(date): ERROR - Failed to create wp-config.php after $max_config_attempts attempts."
        echo "$(date): Creating wp-config.php manually..."

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
        echo "$(date): Created wp-config.php manually."
    fi

    echo "$(date): Final check to ensure database is ready before WordPress installation..."
    wait_for_mariadb_and_setup

    echo "$(date): Installing WordPress core..."
    install_attempts=0
    max_install_attempts=10

    while [ $install_attempts -lt $max_install_attempts ]; do
        install_attempts=$((install_attempts + 1))
        echo "$(date): Installing WordPress core (attempt $install_attempts/$max_install_attempts)..."

        if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE ${MYSQL_DATABASE};" 2>/dev/null; then
            echo "$(date): Database ${MYSQL_DATABASE} is accessible."

            if wp core install --allow-root \
                --url=${DOMAIN_NAME} \
                --title=${WP_TITLE} \
                --admin_user=${WP_ADMIN_USER} \
                --admin_password=${WP_ADMIN_PASSWORD} \
                --admin_email=${WP_ADMIN_EMAIL} \
                --path=/var/www/html; then

                echo "$(date): Successfully installed WordPress core"
                break
            else
                echo "$(date): Failed to install WordPress core. Retrying..."
            fi
        else
            echo "$(date): Database ${MYSQL_DATABASE} is not accessible. Waiting for it to be ready..."
        fi

        sleep 5
    done

    if [ $install_attempts -ge $max_install_attempts ]; then
        echo "$(date): WARNING - Maximum attempts reached for WordPress core installation. WordPress may not be fully installed."
    else
        echo "$(date): Creating additional user..."
        if wp user create --allow-root \
            ${WP_USER} ${WP_USER_EMAIL} \
            --user_pass=${WP_USER_PASSWORD} \
            --role=author \
            --path=/var/www/html; then

            echo "$(date): Successfully created additional user"
        else
            echo "$(date): Failed to create additional user"
        fi
    fi

    echo "$(date): WordPress setup complete!"
else
    echo "$(date): WordPress already configured."
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "$(date): Starting PHP-FPM..."
exec php-fpm7.4 -F