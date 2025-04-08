FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl



COPY ./tools/init-server.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-server.sh

CMD ["/usr/local/bin/init-server.sh"]