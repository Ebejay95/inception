#!/bin/bash

# Logdatei einrichten
LOG_FILE="/var/log/wordpress-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting WordPress configuration script"

# Secrets als Umgebungsvariablen einlesen
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

# Warten bis MariaDB erreichbar ist
echo "$(date): Waiting for MariaDB..."
count=0
max_attempts=60
while ! mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    count=$((count + 1))
    if [ $count -ge $max_attempts ]; then
        echo "$(date): ERROR - Max attempts reached. MariaDB is not accessible."
        break
    fi
    echo "$(date): Waiting for MariaDB... attempt $count/$max_attempts"
    sleep 1
done

# Teste die MariaDB-Verbindung explizit
echo "$(date): Testing database connection..."
if mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null; then
    echo "$(date): Successfully connected to MariaDB"
else
    echo "$(date): ERROR - Failed to connect to MariaDB"
    mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;"
fi

if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
    echo "$(date): WordPress files not found. Downloading WordPress..."
    cd /var/www/html
    wp core download --allow-root

    echo "$(date): Setting permissions"
    chown -R www-data:www-data /var/www/html

    echo "$(date): Creating wp-config.php..."
    wp config create --allow-root \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --path=/var/www/html

    echo "$(date): Installing WordPress core..."
    wp core install --allow-root \
        --url=${DOMAIN_NAME} \
        --title=${WP_TITLE} \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --path=/var/www/html

    echo "$(date): Creating additional user..."
    wp user create --allow-root \
        ${WP_USER} ${WP_USER_EMAIL} \
        --user_pass=${WP_USER_PASSWORD} \
        --role=author \
        --path=/var/www/html

    echo "$(date): WordPress setup complete!"
else
    echo "$(date): WordPress already configured."
fi

echo "$(date): Starting PHP-FPM..."
exec php-fpm7.4 -F