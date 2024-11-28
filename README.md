# Inception

**Virtualize your way to system administration mastery!**

---

## Summary

**Inception** is a system administration project where you set up a small infrastructure using Docker. You will virtualize multiple Docker containers, each dedicated to a specific service, and configure them to work together seamlessly. This project emphasizes Docker basics, network configuration, and secure service management.

---

## Features

### Core Functionality

- **Docker Infrastructure**:
  - Uses `docker-compose` to manage multiple services.
  - Builds containers from custom `Dockerfiles`.

- **Services**:
  - **NGINX**:
    - Configured with TLSv1.2 or TLSv1.3 for secure HTTPS access.
  - **WordPress + php-fpm**:
    - Installed and configured to serve dynamic web content.
  - **MariaDB**:
    - Provides the database backend for WordPress.

- **Volumes**:
  - One for storing WordPress website files.
  - Another for the WordPress database.

- **Networking**:
  - Custom Docker network to connect all containers securely.
  - Containers restart automatically on crash.

- **Security**:
  - Environment variables for credentials.
  - No hardcoded passwords in `Dockerfiles`.
  - Supports `.env` files and Docker secrets for sensitive data.

---

## Structure

### Directories and Files

- **`Makefile`**:
  Automates the setup process:
  - Builds the Docker images.
  - Configures the infrastructure using `docker-compose`.

- **`srcs/`**:
  Contains all project configurations:
  - **`docker-compose.yml`**:
    - Defines the container setup, network, and volumes.
  - **`requirements/`**:
    - Subdirectories for each service (`nginx`, `wordpress`, `mariadb`) with their respective `Dockerfiles` and configurations.
  - **`.env`**:
    - Stores environment variables such as domain name and database credentials.
  - **`secrets/`**:
    - Securely stores sensitive information like passwords.

### Example Directory Layout

. ├── Makefile ├── srcs/ │ ├── docker-compose.yml │ ├── .env │ ├── requirements/ │ │ ├── nginx/ │ │ │ ├── Dockerfile │ │ │ ├── conf/ │ │ │ └── tools/ │ │ ├── wordpress/ │ │ │ ├── Dockerfile │ │ │ ├── conf/ │ │ │ └── tools/ │ │ ├── mariadb/ │ │ ├── Dockerfile │ │ ├── conf/ │ │ └── tools/ ├── secrets/ │ ├── db_password.txt │ ├── db_root_password.txt │ └── credentials.txt

yaml
Code kopieren

---

## Example Usage

### Compilation

1. **Clone the Repository**:
```bash
   git clone <repository_url>
   cd inception
```

### Set Up Environment Variables: Edit .env with your domain and credentials:

```
DOMAIN_NAME=your_login.42.fr
MYSQL_USER=username
MYSQL_PASSWORD=your_password
```

### Build and Start the Infrastructure:

```
make
```

Access Your Website: Open https://your_login.42.fr in a browser.

## Configuration Requirements
###NGINX:
Entry point for all traffic (HTTPS only, port 443).
Configured with custom TLS certificates.

## WordPress:
Two user accounts, including one non-admin user.

## MariaDB:
Handles the WordPress database.
Security Best Practices

## Environment Variables:
Use .env to store sensitive information.

##Secrets:
Store passwords in files under secrets/ and ignore them in Git.

##No Hardcoded Credentials:
Ensure all credentials are dynamically loaded.
Learning Outcomes

## Docker Basics:
Build, manage, and configure containers.

## Networking:
Set up secure container communication.

## System Administration:
Automate tasks and enforce best practices.

## Web Services:
Deploy web servers and databases in containers.

Inception – Dockerize your way into system administration excellence! 🚀


```
secrets:

secrets/db_password.txt           secureDBpass123!
secrets/db_root_password.txt      rootSecurePass456!
secrets/wp_password.txt           superSecureWPpass789!
```


