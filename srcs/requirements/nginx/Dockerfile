FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl gettext-base

RUN mkdir -p /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf.template

COPY ./tools/init-server.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-server.sh

RUN groupadd -r nginx && useradd -r -g nginx nginx

RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run/nginx && \
	chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run/nginx /etc/nginx/ssl

EXPOSE 443

CMD ["/usr/local/bin/init-server.sh"]