FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY ./tools/init-db.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/init-db.sh

CMD ["/usr/local/bin/init-db.sh"]