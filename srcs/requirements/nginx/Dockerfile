FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl

RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/nginx.key \
	-out /etc/nginx/ssl/nginx.crt \
	-subj "/C=XX/ST=State/L=City/O=Organization/OU=Unit/CN=jeberle.42.fr"

COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf

RUN groupadd -r nginx && useradd -r -g nginx nginx

RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run/nginx /etc/nginx/ssl

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]