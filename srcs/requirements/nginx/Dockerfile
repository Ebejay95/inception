# requirements/nginx/Dockerfile
FROM debian:buster

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# SSL setup script
COPY tools/ssl_setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ssl_setup.sh

# NGINX configuration
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Generate SSL certificate
RUN /usr/local/bin/ssl_setup.sh

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]