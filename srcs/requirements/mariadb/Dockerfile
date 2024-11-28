FROM debian:buster

RUN apt-get update && apt-get install -y \
	mariadb-server

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/db-setup.sh /usr/local/bin/

EXPOSE 3306

CMD ["mysqld"]